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
  next if ($link->as_HTML() =~ /img/ || $link->attr("href") =~ /rss/ || $link->attr("href") =~ /javascript/);
  next if $done{$link->attr("href")}; #stripping out duplicate urls. every table row has three, one is an img so that's removed earlier
  my $part = KivaPart->new_from_url($link->attr("href"));
  $part->insertDB($dbh);
  $done{$link->attr("href")} = 1;
}
#insert
$tree->delete();
#going to set up the search results, title on first page's last page is 'last page'
#so from 1 to $lastlink->as_trimmed_text() are valid page ids

my $page = 1;
my $url_base = "http://www.kiva.org/app.php?page=businesses&pageID=";

$res = $ua->get("$url_base$page");
unless ($res->is_success)
{
    print "Error: unable to retrieve first page\n";
    print "Status is: ".$res->status_line."\n";
    exit;
}

$tree = HTML::TreeBuilder->new_from_content($res->content);
my ($link) = $tree->look_down("_tag" => "a", "title" => "last page");
unless ($link){print "Error: no last page link found\n";exit;}

my $maxpage = $link->as_trimmed_text();
$tree->destroy(); #this might be an unneeded grab, but since I change the sorting I don't want to miss something

for ($page=1; $page <= $maxpage; $page++)
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
    for $link (@links){
	next if ($link->as_HTML() =~ /img/ || $link->attr("href") =~ /rss/);
	next if $done{$link->attr("href")}; #stripping out duplicate urls. every table row has three, one is an img so that's removed earlier
	my $ent = KivaEnt->new_from_url($link->attr("href"));
	$ent->insertDB($dbh) unless $ent->inDB($dbh);
	$done{$link->attr("href")} = 1;
    }
    
    $tree->destroy();
}

#########Insert partner parsing here#############################
#Pretty much going to do the same as above except with the partners
# Each ent should have the partner id in their data, so it's pretty much
# just a foreign key in the database to the id on the partner table
# Look over every partner href, pull the data, insert the data.
# All the data extraction should already be set up in the partner
# module
################################################################



$dbh->disconnect;
