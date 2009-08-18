#!/usr/bin/perl
use warnings;
use strict;

#used to make requests and parse the returned pages.
use LWP::UserAgent;
use HTML::TreeBuilder;

use lib 'modules';
use KivaEnt; #represent an entrepenuer. 
use KivaPart;

#file info, handlers, methods
my $csv = "csv/kiva.csv";
my $file = open CSV, "<$csv"; # or die "Fatal Error: Can't open cvs file\n";

my %ents = ();
#build each ent, and make sure each is newest version
if ($file){
    my $throwaway = <CSV>;
    while (<CSV>)
    {
	my ($tmp, $part) = new KivaEnt($_);
	$tmp->setPartner(new KivaPart($part));
	$ents{$tmp->getId()} = $tmp;# if (!$ents{$tmp->getId()} || 
				    #$ents{$tmp->getId()}->is_newer($tmp));
    }
}
else{
    open CSV, ">$csv"; #clobber the file so we can put in the column headers
    print CSV "Type\tTime\tURL\tID\tName\tActivity\tLoanAmt\tDaysLeft\tCountry\tUse\tRepayRate\tLenderRepaid\tListDate\tDisbursmentDate\t
Fundraising\tTimeOnKiva\tEntrepOnKiva\tTotalLoans\tDelinquentRate\tDefaultRate\tGroupName\tGroupMembers\tLocation\tCurrencyExchag\t
CurrencyExchangeLoss\tAverageIncome\tCurrency\tExchangeRate\tDescription\tLoanReq\tRaised\tNeeded\tPartnerID\tFieldPartner\t
PartnerRating\tPartStartDate\tPartTimeOnKiva\tPartKivaEnts\tPartTotalLoans\tPartDelinqRate\tPartDefRate\tPartExchageLoss\t
PartFundStatus\tPartNetworkAffs\tPartEmailContact\tPartWomenEnts\tPartAveLoanAmt\tPartAveIndLoan\tPartAveGrpLoan\tPartAveEntsGroupt\t
PartAveLocalGDP\tPartAveLoanToGDP\tPartAveRaised\tPartAveLoanTerm\tPartTotalJournals\tPartJournalCoverage\tPartJournCovKivaEnts\t
PartJournalsFreq\tPartAveRecommend\tPartAveInterest\tPartAveLocalInterest\n";
}
close CSV; #not needed anymore (for now)

#going to set up the search results, title on first page's last page is 'last page'
#so from 1 to $lastlink->as_trimmed_text() are valid page ids

my $page = 1;
my $url_base = "http://www.kiva.org/app.php?page=businesses&pageID=";
my $ua = new LWP::UserAgent;
$ua->cookie_jar({});

my $res = $ua->get("$url_base$page");
unless ($res->is_success)
{
    print "Error: unable to retrieve first page\n";
    print "Status is: ".$res->status_line."\n";
    exit;
}

my $tree = HTML::TreeBuilder->new_from_content($res->content);
my ($link) = $tree->look_down("_tag" => "a", "title" => "last page");
unless ($link){print "Error: no last page link found\n";exit;}

my $maxpage = $link->as_trimmed_text();
$tree->destroy(); #this might be an unneeded grab, but since I change the sorting I don't want to miss something

#print "maxpage is: $maxpage\n";
my @add_line = ();

open CSV, ">>$csv";

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
    my %done = ();
    print "Found: ",scalar(@links)," anchor tags\n";
    for $link (@links){
	next if ($link->as_HTML() =~ /img/ || $link->attr("href") =~ /rss/);
	next if $done{$link->attr("href")}; #stripping out duplicate urls. every table row has three, one is an img so that's removed earlier
#	print "url: ",$link->attr("href"), "\n";
	my $ent = KivaEnt->new_from_url($link->attr("href"));
	$ent->setPartner(KivaPart->new_from_id($ent->getPartId));
#	print $ent->getId().": ";
	if (!$ents{$ent->getId()} ||
	    ($ent->is_different($ents{$ent->getId()}))){
	    #push @add_line, $ent;
#	    print "Different\n" if !$ents{$ent->getId()};
	    my $out = $ent->to_string();
	    print CSV join("\t", @$out), "\n";
	}
	$done{$link->attr("href")} = 1;
    }
    
    $tree->destroy();
}

#open CSV, ">>$csv";

#for my $ent (@add_line){
#    print CSV $ent->to_string(), "\n";
#}

close CSV;
