#!/usr/bin/perl
use warnings;
use strict;

#used to make requests and parse the returned pages.
use LWP::UserAgent;
use HTML::TreeBuilder;
use DBI;
use Data::Dumper;

use lib 'modules';
use KivaEnt; #represent an entrepenuer. 
use KivaPart;

my $dbserver = 'localhost';
my $dbname = 'kivaparsing';
my $dbuser = 'kivaparsin';
my $dbpass = 'db4kiva!';

my $dbh = DBI->connect("dbi:mysql:database=$dbname;host=$dbserver", $dbuser, $dbpass) 
	or die "Error connecting to database: ".DBI->errstr."\n";

my $ua = new LWP::UserAgent;
$ua->cookie_jar({});

#grab partner page
my $res = $ua->get("http://www.kiva.org/about/partners/");
die "Error retrieving partner page: ".$res->status_line."\n" unless $res->is_success;
#extract links
my $tree = HTML::TreeBuilder->new_from_content($res->content);
my ($partgrid) = $tree->look_down("_tag" => "table", "class" => "kvDataGrid");
#scrape each partner
my @part_links = $partgrid->look_down("_tag" => "a");
my %done = ();
for my $link (@part_links){
  next if ($link->as_HTML() =~ /img/ || $link->attr("href") =~ /rss/ || $link->attr("href") =~ /javascript/ || $link->attr("href") =~ /#/);
  next if $done{$link->attr("href")}; #stripping out duplicate urls. every table row has three, one is an img so that's removed earlier
  my $part = KivaPart->new_from_url($link->attr("href"));
  $part->insertDB($dbh);
  $done{$link->attr("href")} = 1;
}
#insert
$tree->destroy();
#going to set up the search results, title on first page's last page is 'last page'
#so from 1 to $lastlink->as_trimmed_text() are valid page ids

my $url_base = "http://www.kiva.org/app.php?page=businesses&pageID=";
for (my $page = 1; 1==1; $page++)

{
    $res = $ua->get("$url_base$page");
    unless ($res->is_success)
    {
	print "Error: unable to retrieve page $page, which should be valid\n";
	print "Status is: ".$res->status_line."\n";
	exit;
    }
    print "Fetched: $url_base$page\n";
    print "Status is: ".$res->status_line."\n";
    $tree = HTML::TreeBuilder->new_from_content($res->content);
    my ($grid) = $tree->look_down("_tag" => "table", "class" => "kvDataGrid");
    last if !$grid;
    my @links = $grid->look_down("_tag" => "a");
    %done = ();
    print "Found: ",scalar(@links)," anchor tags\n";
    my $position = 1;
    for my $link (@links){
	next if ($link->as_HTML() =~ /img/ || $link->attr("href") =~ /rss/ || $link->attr("href") =~ /javascript/ || $link->attr("href") =~ /#/);
	next if $done{$link->attr("href")}; #stripping out duplicate urls. every table row has three, one is an img so that's removed earlier
	my $ent = KivaEnt->new_from_url($link->attr("href"));
	$ent->insertDB($dbh) unless $ent->inDB($dbh);
	$done{$link->attr("href")} = 1;
	$ent->insertPosition($dbh, $page, $position);
	$position++;
    }
    $tree->destroy();
    if ($position < 2) {last;} #past last page, no links processed
}

$dbh->disconnect;
