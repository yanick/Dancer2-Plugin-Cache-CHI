package TestApp;

use strict;
use warnings;

use lib 't';

use Test::More;

use Dancer2 qw/:syntax :tests /;
use Dancer2::Plugin::Cache::CHI;

use Dancer2::Test;

set plugins => {
    'Cache::CHI' => { driver => 'Memory', global => 1, expires_in => '1 min' },
};

hook before_create_cache => sub {
    config->{plugins}{'Cache::CHI'}{namespace} = 'Foo';
};

get '/namespace' => sub {
    cache->namespace;
};

plan tests => 1;

response_content_is '/namespace', 'Foo', 'namespace configured';
