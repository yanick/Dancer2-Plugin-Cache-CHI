package Dancer2::Plugin::Cache::CHI;
# ABSTRACT: Dancer plugin to cache response content (and anything else)

use strict;
use warnings;
use Carp;
use CHI;
use List::MoreUtils qw/ any /;

use Dancer2::Plugin;

plugin_hooks 'before_create_cache';

# actually hold the ref to the args
has _cache_page => (
    is        => 'rw',
    clearer   => 'clear_cache_page',
    predicate => 'has_cache_page',
);

has cache_page_key_generator => (
    is             => 'rw',
    lazy           => 1,
    plugin_keyword => 1,
    default        => sub {
        sub { $_[0]->app->request->path }
    },
);

sub BUILD {
    my $plugin = shift;

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after',
            code => sub {
                return unless $plugin->has_cache_page;

                my $resp = shift;
                $plugin->cache->set( $plugin->cache_page_key_generator->($plugin),
                    {
                        status      => $resp->status,
                        headers     => $resp->headers_to_array,
                        content     => $resp->content
                    },
                    @{$plugin->_cache_page},
                );

                $plugin->clear_cache_page;
            }
    ));

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                $plugin->clear_cache_page;
            }
    ));
};

has _caches => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        {}
    },
);

has caches_with_honor => (
    is      => 'ro',
    default => sub{ {} },
);

plugin_keywords 'cache';

sub cache {
    my( $self, $namespace ) = @_;
    $namespace //= '';
    return $self->_caches->{$namespace} ||= _create_cache( $self, $namespace, @_ );
};

sub _create_cache {
    my( $dsl, $namespace, $args ) = @_;
    $args ||= {};

    $dsl->execute_hook( 'plugin.cache_chi.before_create_cache' );

    my %setting = ( %{ $dsl->config }, %$args );

    $setting{namespace} //= $namespace;

    $dsl->caches_with_honor->{$namespace} = delete $setting{honor_no_cache};

    return CHI->new(%setting);
}


plugin_keywords check_page_cache => sub {
    my $dsl = shift;

    my $hook = sub {
        my $context = shift;

        # Instead halt() now we use a more correct method - setting of a
        # response to Dancer2::Core::Response object for a more correct returning of
        # some HTTP headers (X-Powered-By, Server)

        my $cached = cache($dsl)->get( $dsl->cache_page_key_generator->($dsl) )
            or return;

        if ( $dsl->caches_with_honor->{''} ) {

            my $req =  $dsl->app->request;

            no warnings 'uninitialized';

            return if any {
                $req->header($_) eq 'no-cache'
            } qw/ Cache-Control Pragma /;
        }

        $context->set_response(
        	Dancer2::Core::Response->new(
                is_halted => 1,
                ref $cached eq 'HASH'
                ?
                ( map { $_ => $cached->{$_} } qw/ status headers content / )
                :
                ( content => $cached )
            )
		);
    };

    $dsl->app->add_hook( Dancer2::Core::Hook->new(
        name => 'before',
        code => $hook,
    ));
};

plugin_keywords cache_page => sub {
    my ( $plugin, $content, @args ) = @_;

    $plugin->_cache_page(\@args);

    return $content;
};

plugin_keywords cache_page_key => sub { $_[0]->cache_page_key_generator->($_[0]) };

for my $method ( qw/ set get remove clear compute / ) {
    plugin_keywords "cache_$method" => sub {
        my $plugin = shift;
        $plugin->cache->$method(@_);
    }
}

1;

__END__
