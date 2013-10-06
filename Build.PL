
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Dancer plugin to cache response content (and anything else)",
  "dist_author" => [
    "Yanick Champoux <yanick\@cpan.org>"
  ],
  "dist_name" => "Dancer2-Plugin-Cache-CHI",
  "dist_version" => "1.5.2",
  "license" => "perl",
  "module_name" => "Dancer2::Plugin::Cache::CHI",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "CHI" => 0,
    "Carp" => 0,
    "Dancer2" => "0.10",
    "Dancer2::Plugin" => 0,
    "Moo" => "1.000007",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Dancer2::Test" => 0,
    "Test::More" => "0.88",
    "lib" => 0,
    "perl" => "v5.10.0"
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
