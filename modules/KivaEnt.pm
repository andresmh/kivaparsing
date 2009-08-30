#!/usr/bin/perl
package KivaEnt;
use warnings;
use strict;

use LWP::UserAgent;
use HTML::TreeBuilder;
use Date::Parse;

use Data::Dumper;

my $tld = "http://www.kiva.org/";


#set up prepared queries
my $chkqry = q{
SELECT 1 
FROM kiva_ent 
WHERE 
	id = ?
	AND type = ?
	AND activity = ?
	AND loanamt = ?
	AND daysleft = ?
	AND country = ?
	AND partner = ?
	AND loan_use = ?
	AND repayrate = ?
	AND repaid = ?
	AND listdate = ?
	AND disbursmentdate = ?
	AND timeonkiva = ?
	AND entreponkiva = ?
	AND totalloans = ?
	AND delinquentrate = ?
	AND defaultrate = ?
	AND location = ?
AND averageincome = ?
AND loanreq = ?
AND raised = ?
AND needed = ?
AND description = ?
};

sub inDB{
  my $self = shift;
  my $dbh = shift;
  my @params = ();
  foreach (qw/ id type act loan days country part_id use repay repaid listed disb 
	     kiva_time kiva_ents tot_loans delinq default location ave_income loan_req raised needed short/){
	    push @params, ($self->{$_}?$self->{$_}:"");
    }
  my $rows = $dbh->selectall_arrayref($chkqry, {}, @params) or die "Error selecting from database: ".$dbh->errstr."\n";
  return (scalar(@$rows) > 0);
}


my $ins_qry = q{
INSERT INTO kiva_ent(type, time, url, id, name, activity, loanamt, daysleft, country, loan_use, repayrate, partner, repaid, listdate, 
disbursmentdate, fundraising, timeonkiva, entreponkiva, totalloans, delinquentrate, defaultrate, groupname, groupmembers, location, 
currencyexchange, currencyexchangeloss, averageincome, currency, exchangerate, description, loanreq, raised, needed)
VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
};

sub insertDB {
  my $self = shift;
  my $dbh = shift;
  my @params = ();
foreach (qw/ type time url id name act loan days country use repay partner repaid listed disb 
	     fund kiva_time kiva_ents tot_loans delinq default group_name group_members
	     location curr_x curr_rate ave_income curr x_rate short loan_req raised needed/){
	if ($_ eq "time"){
	    my ($sec,$min,$hour,$mday,$mon,$year) = localtime($self->{$_});
	    push @params, sprintf("%4u-%02u-%02u %02u:%02u:%02u", $year+1900, $mon, $mday, $hour, $min, $sec);
	}
	else{
	    push @params, ($self->{$_}?$self->{$_}:"");
	}
    }
   $dbh->do($ins_qry, {}, @params) or die "Error inserting ent: ".$dbh->errstr."\n";
}

#utility functions for the class

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
