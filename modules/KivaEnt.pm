#!/usr/bin/perl
package KivaEnt;
use warnings;
use strict;

use LWP::UserAgent;
use HTML::TreeBuilder;
use Date::Parse;

use Data::Dumper;

my $tld = "http://www.kiva.org/";

sub new{
    my ($pkg, $string) = @_;
    return undef unless $string;
    my $self = {};
    chomp $string;
    my ($type, $time, $url, $id,$name, $act, $loan, $days, $country, $use, $repay, $repaid, $listed, $disb,
             $fund, $kiva_time, $kiva_ents, $tot_loans, $delinq, $default, $group_name, $group_members,
	 $location, $curr_x, $curr_rate, $ave_income, $curr, $x_rate, $short, $loan_req, $raised, $needed, $partid, $partner, 
	$part_rating, $part_kivastart, $part_kivatime, $part_kivaents, $part_totloans, $part_delinq, $part_default, $part_xloss,
	$part_fundstat, $part_network, $part_email, $part_womenents, $part_aveloan, $part_aveindloan, $part_avegrploan, 
	$part_aveentsgroup, $part_avelocalgdp, $part_aveloangdp, $part_aveloanfund, $part_averaised, $part_aveterm, $part_totjourn,
	$part_journcov, $part_journcovkiva, $part_journfreqloan, $part_averecom, $part_interpart, $part_localinter) =
	    split(/\t/, $string);
    $self->{'type'} = $type;
    $self->{'time'} = str2time($time);
    $self->{'url'} = $url;
    $self->{'id'} = $id;
    $self->{'name'} = $name;
    $self->{'act'} = $act;
    $self->{'loan'} = $loan;
    $self->{'days'} = $days;
    $self->{'country'} = $country;
    $self->{'partner'} = $partner;
    $self->{'part_id'} = $partid;
    $self->{'short'} = $short;
    $self->{'use'} = $use;
    $self->{'repay'} = $repay;
    $self->{'repaid'} = $repaid;
    $self->{'listed'} = $listed;
    $self->{'disb'} = $disb;
    $self->{'fund'} = $fund;
    $self->{'kiva_time'} = $kiva_time;
    $self->{'kiva_ents'} = $kiva_ents;
    $self->{'tot_loans'} = $tot_loans;
    $self->{'delinq'} = $delinq;
    $self->{'default'} = $default;
    $self->{'group_name'} = $group_name;
    $self->{'group_members'} = $group_members;
    $self->{'location'} = $location;
    $self->{'curr_x'} = $curr_x;
    $self->{'curr_rate'} = $curr_rate;
    $self->{'ave_income'} = $ave_income;
    $self->{'curr'} = $curr;
    $self->{'x_rate'} = $x_rate;
    $self->{'loan_req'} = $loan_req;
    $self->{'raised'} = $raised;
    $self->{'needed'} = $needed;
    my $part = {
	id => $partid,
FieldPartnerRiskRating =>$part_rating,
FieldPartner => $partner,
StartDateOnKiva =>$part_kivastart,
TimeOnKiva =>$part_kivatime,
KivaEntrepreneurs =>$part_kivaents,
TotalLoans =>$part_totloans,
DelinquencyRate =>$part_delinq,
DefaultRate =>$part_default,
CurrencyExchangeLossRate =>$part_xloss,
FundraisingStatus =>$part_fundstat,
NetworkAffiliation =>$part_network,
EmailContact =>$part_email,
LoanstoWomenEntrepreneurs =>$part_womenents,
AverageLoanSize =>$part_aveloan,
AverageIndividualLoanSize =>$part_aveindloan,
AverageGroupLoanSize =>$part_avegrploan,
AverageNumberOfEntrepreneursPerGroup =>$part_aveentsgroup,
AverageGDPPerCapitaPPPinLocalCountry =>$part_avelocalgdp,
AverageLoanSizeGDPPerCapitaPPP =>$part_aveloangdp,
AverageTimeToFundALoan =>$part_aveloanfund,
AverageDollarsRaisedPerDayPerLoan =>$part_averaised,
AverageLoanTerm =>$part_aveterm,
TotalJournals =>$part_totjourn,
JournalCoverage =>$part_journcov,
JournalCoverageKivaFellows =>$part_journcovkiva,
JournalFrequencyAveragePerLoanPerYear =>$part_journfreqloan,
AverageNumberOfRecommendationsPerJournal =>$part_averecom,
AverageInterestRateBorrowerPaysToKivaFieldPartner =>$part_interpart,
AverageLocalMoneyLenderInterestRate =>$part_localinter
    };
    bless $self, $pkg;
    return ($self, $part);
}

#utility functions for the class
sub is_newer{
    my ($self, $targ) = @_;
    
    return ($self->{time} > $targ->{time});
}

sub is_different{
    my ($self, $targ) = @_;
    foreach (qw/ type id act loan days country partner part_id use repay repaid listed disb
             fund kiva_time kiva_ents tot_loans delinq default
	 location curr_x curr_rate ave_income curr x_rate short loan_req raised needed/){
	next if (!$self->{$_} && !$targ->{$_});
	if (($self->{$_} && !$targ->{$_})||
	    (!$self->{$_} && $targ->{$_})||
	    (clean($self->{$_}) ne clean($targ->{$_}))){
#	    printf("'%s' is different from '%s'\n",$self->{$_},$targ->{$_});
	    return 1;
	}
    }
    return $self->{'part_obj'}->is_different($targ->{'part_obj'});
}

sub setPartner{
    my ($self, $part) = @_;
    $self->{'part_obj'} = $part;
}

sub new_from_url{
    my ($pkg, $url) = @_;
    my $self = {};
    my $ua = new LWP::UserAgent();
    my $res = $ua->get($tld.$url);
    if (!$res->is_success){
	print "Warning: unable to retrieve page: $url\nStatus: ".$res->status_line."\n";
	return undef;
    }
    print "KivaEnt Fetched: $tld.$url\n";
    print "Status is ".$res->status_line."\n";
    my $tree = HTML::TreeBuilder->new_from_content($res->content);
    my ($data) = $tree->look_down("_tag" => "div", "class" => "kvInfoBox");
    return undef unless $data;

    my %values = ();
    for my $nvp ($data->look_down("_tag"=>"tr")){
#	print $nvp->as_HTML(),"\n";
	my @tmp = split(/:/, $nvp->as_text(), 2);
	next if (scalar(@tmp) < 2); #a value isn't present, skip it.
	$tmp[0] =~ s/\W//g;
      	$values{clean($tmp[0])} =  clean($tmp[1]);
	if ($tmp[0] eq "FieldPartner"){
	    my ($about,$href) = $nvp->look_down("_tag"=>"a");
	    $values{'part_id'} = (split(/=/, $href->attr("href"),2))[1];
	}
#	$values{clean($tmp[0])} =$tmp[1] if $tmp[0] =~ /Loan/;
#	printf("Values: %s - %s\n", $tmp[0], $tmp[1]);
    }

    if ($values{'GroupName'}){
	$self->{'group_name'} = $values{'GroupName'};
	$self->{'group_members'} = $values{'GroupMembers'};
	$self->{'type'} = "Group";
    }
    elsif ($values{'Name'}){
	$self->{'type'} = "Single";
	$self->{'name'} = $values{'Name'};
    }
    else{
	print "Warning: Bad data received from $url\n";
	return undef;
    }
#    print $values{'LoanAmount'}."\n";

#    print Dumper(\%values),"\n";
    $self->{'act'} = $values{'Activity'};
    $self->{'loan'} = $values{"LoanAmount"};
    $self->{'partner'} = $values{'FieldPartner'};
    $self->{'part_id'} = $values{'part_id'};
    $self->{'use'} = $values{'LoanUse'};
    $self->{'repaid'} = $values{'LendersRepaid'};
    $self->{'repay'} = $values{'RepaymentTerm'};
    $self->{'listed'} = $values{'DateListed'};
    $self->{'disb'} = $values{'DateDisbursed'};
    $self->{'location'} = $values{'Location'};
    $self->{'curr_x'} = $values{'CurrencyExchangeLoss'};
    $self->{'fund'} = $values{'FundraisingStatus'};
    $self->{'kiva_time'} = $values{'TimeOnKiva'};
    $self->{'kiva_ents'} = $values{'KivaEntrepreneurs'};
    $self->{'tot_loans'} = $values{'TotalLoans'};
    $self->{'delinq'} = $values{'DelinquencyRate'};
    $self->{'default'} = $values{'DefaultRate'};
    $self->{'curr_rate'} = $values{'CurrencyExchangeLossRate'};
    $self->{'country'} = $values{'Country'};
    $self->{'ave_income'} = $values{'AvgAnnualIncome'};
    $self->{'curr'} = $values{'Currency'};
    $self->{'x_rate'} = $values{'ExchangeRate'};

    $url =~ /id=(\d+)/i;
    $self->{'id'} = $1;
    $self->{'time'} = time;
    $self->{'url'} = $url;

  #  loan_req raised needed
    
    my @rows = ($tree->look_down("_tag" => "div", "class" => "kvActionBox"))[0]->look_down("_tag" => "tr");
    for my $row (@rows){
	if ($row->as_HTML() =~ /(Request|Raised|needed)/i){
	    #print $row->as_trimmed_text(), "\n";
	    my $t = $row->as_trimmed_text();
	    next unless ($t =~ /\s*\$(\d[,\d]*\.\d\d)/i);
	    #print "$1\n";
	    my $amt = $1;
	    if ($t =~ /Request/i){
		$self->{'loan_req'} = $amt;
	    } elsif ($t =~ /Raised/i){
		$self->{'raised'} = $amt;
	    } else {
		$self->{'needed'} = $amt;
	    }
	}
    }
    my ($days) = ($tree->look_down("_tag" => "div", "class" => "kvActionBox"))[0]->look_down("_tag" => "center");
    $self->{'days'} = ($days? clean($days->as_trimmed_text()): 0);

#    for my $k (sort keys %$self){print "$k - ".($$self{$k} || ""),"\n";}

    unless (-e "images/".$self->{'id'}.".jpg"){
	my $img_loc = (($tree->look_down("_tag"=>"div", "class"=>"boxMain"))[0]->look_down("_tag" => "img"))[1]->parent()->attr("href");
	if ($img_loc){
	    my $img_res = $ua->get($img_loc, ":content_file" => "images/".$self->{'id'}.".jpg");
	    if (!$img_res->is_success){
		print "Warning: failed to download image from $img_loc\n";
		print "Target profile was $url\n";
		print "Status: ".$img_res->status_line."\n";
	    }
	}
    }
    $self->{'short'} = clean($data->right()->right()->right()->as_text());

    $tree->destroy;
    bless $self, $pkg;
    return $self;
}

sub to_string{
    my ($self) = @_;
    my @ret = ();
    foreach (qw/ type time url id name act loan days country partner part_id use repay repaid listed disb 
	     fund kiva_time kiva_ents tot_loans delinq default group_name group_members
	     location curr_x curr_rate ave_income curr x_rate short loan_req raised needed/){
	if ($_ eq "time"){
	    my ($sec,$min,$hour,$mday,$mon,$year) = localtime($self->{$_});
	    push @ret, sprintf("%4u-%02u-%02u %02u:%02u:%02u", $year+1900, $mon, $mday, $hour, $min, $sec);
	}
	else{
	    push @ret, ($self->{$_}?$self->{$_}:"");
	}
#	printf("%s : %s\n", $_, $self->{$_});
    }
    push @ret, $self->{'part_obj'}->to_string(); 
    return \@ret;
}

#to ensure that the delimiting character is not in any field we present to the CSV file
sub clean{
    my $str = shift;
    return undef unless $str;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $str =~ s/\t//;
    return $str;
}

sub getId{
    my $self = shift;
    return $self->{'id'};
}

sub getPartId{
    my $self=shift;
    return $self->{'part_id'};
}

1;
