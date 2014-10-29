#!/usr/bin/perl

package ForeachNewRev;

use strict;
use warnings;
use utf8;

BEGIN {
  require Exporter;
  our $VERSION = 1.0;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(foreach_new_rev);
}

sub foreach_new_rev {
  my ($fun) = @_;

  # ----------- ARGV

  die 'not meant to be run manually'
    unless (scalar(@ARGV) > 7);

  my ($ref, $oldsha, $newsha, $oldtree, $newtree, $access, $refex) = @ARGV;

  # ----------- exclude (from rev-list)

  my @exclude;
  if ($oldsha eq '0000000000000000000000000000000000000000') {
    open GH, '-|', 'git', 'for-each-ref', '--format', '^%(refname:short)', 'refs/heads/'
      or die "failed: git for-each-ref: $!";
    @exclude = <GH>;
    close GH;
  }
  else {
    @exclude = ('^' . $oldsha);
  }
  chomp @exclude;

  # ----------- rev-list (new pushed commits)

  open GH, '-|', 'git', 'rev-list', '--reverse', $newsha, @exclude
    or die "failed: git rev-list: $!";
  my @revlist = <GH>;
  close GH;
  chomp @revlist;

  # ----------- for each new commit...
  my $list = '';
  my $first = '';
  my $last = '';

  foreach my $commit (@revlist) {
    my $result = $fun->($commit);

    if (length $result) {
      $list .= "\n" . '  ' . $commit . "\n";
      if (!length $first) {
        $first = $commit;
      }
      $list .= $result;
    }

    if (length $first) {
      $last = $commit;
    }
  }

  # ----------- print refex

  if (length $list) {
    print "\n";
    print "Standards would be violated, were this push accepted.\n";

    if ($last eq $first) {
      print 'Fix the files below, `git add\' them and `git commit --amend`.', "\n";
    }
    else {
      print 'Fix all affected commits below using `git rebase -i ' . $first . '^`.', "\n";
    }

    print $list;
    print "\n";

    print $refex, "\n";
  }
}

1;
