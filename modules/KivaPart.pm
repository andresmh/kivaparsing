#!/usr/bin/perl
package KivaPart;
use warnings;
use strict;

use LWP::UserAgent;
use HTML::TreeBuilder;
use Date::Parse;

use Data::Dumper;

my $tld = "http://www.kiva.org/";

my $part_ins = q{
INSERT into kiva_parts(partnerid, fieldpartner, rating, startdate, timeonkiva, kivaents, totalloans, delinqrate, defrate, exchangeloss,
fundingstatus, networkaffs, emailcontact, womenents, averateloanamt, aveindloan, avegrploan, aveentsgroup, avelocalgdp, averaised,aveloanterm,
totaljournals,journalcoverage,journalkivaents,journalsfreq,averecommend,aveinterest,avelocalinterest)
VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
};

sub insertDB{
  my $self = shift;
  my $dbh = shift;
  my @params = ();
  foreach (qw/ id FieldPartner FieldPartnerRiskRating StartDateOnKiva TimeOnKiva KivaEntrepreneurs TotalLoans DelinquencyRate DefaultRate 
CurrencyExchangeLossRate FundraisingStatus NetworkAffiliation EmailContact LoanstoWomenEntrepreneurs AverageLoanSize AverageIndividualLoanSize
 AverageGroupLoanSize
AverageNumberOfEntrepreneursPerGroup AverageGDPPerCapitaPPPinLocalCountry AverageLoanSizeGDPPerCapitaPPP AverageTimeToFundALoan
AverageDollarsRaisedPerDayPerLoan AverageLoanTerm TotalJournals JournalCoverage JournalCoverageKivaFellows JournalFrequencyAveragePerLoanPerYear
AverageNumberOfRecommendationsPerJournal AverageInterestRateBorrowerPaysToKivaFieldPartner AverageLocalMoneyLenderInterestRate/){
	    push @params, ($self->{$_}?$self->{$_}:"");
    }
  $dbh->do($part_ins, {}, @params) or die "Error inserting partner: ".$dbh->errstr."\n";
}

sub new{
    my ($pkg, $attrs) = @_;
    return undef unless $attrs;
    my $self = $attrs;
    bless $self, $pkg;
    return $self;
}

sub new_from_id{
    my ($pkg, $url) = @_;
    return undef unless $url;
    my $self = {};
    my $ua = new LWP::UserAgent();
    my $res = $ua->get($tld."about/aboutPartner?id=$url");
    if (!$res->is_success){
	print "Warning: unable to retrieve page: $url\nStatus: ".$res->status_line."\n";
	return undef;
    }
    print "KivaPart Fetched: ".$tld."about/aboutPartner?id=$url\n";
    print "Status: ".$res->status_line."\n";
    my $tree = HTML::TreeBuilder->new_from_content($res->content);
    my @stats = $tree->look_down("_tag" => "div", "class" => "kvInfoBox");
    return undef unless (@stats > 0);

    my %values = ();
    for my $data (@stats){
	for my $nvp ($data->look_down("_tag"=>"tr")){
#	print $nvp->as_HTML(),"\n";
	    my @conts = $nvp->content_list();
	    while ((@conts > 1) && ($conts[0]->as_trimmed_text() eq "")){ shift @conts;}
	    next if (@conts < 2);
	    my $label = $conts[0]->as_trimmed_text();
	    my $value = $conts[1]->as_trimmed_text();
	    $label =~ s/\W//g;
	    $values{clean($label)} =  clean($value);
#	$values{clean($tmp[0])} =$tmp[1] if $tmp[0] =~ /Loan/;
	    $values{clean($label)} =  clean($conts[1]->as_HTML()) if ($label =~ /Risk\s?Rating/);
#	    printf("Values: %s - %s\n", $label, $value);
	}
    }

    $self->{'FieldPartnerRiskRating'} += () = $values{'FieldPartnerRiskRating'} =~ /(on_small)/g; 
#counting the number of stars on_small vs off_small

    $self->{'FieldPartner'} = $values{'FieldPartner'};
    $self->{'StartDateOnKiva'} = $values{'StartDateOnKiva'};
    $self->{'TimeOnKiva'} = $values{'TimeOnKiva'};
    $self->{'KivaEntrepreneurs'} = $values{'KivaEntrepreneurs'};
    $self->{'TotalLoans'} = $values{'TotalLoans'};
    $self->{'DelinquencyRate'} = $values{'DelinquencyRate'};
    $self->{'DefaultRate'} = $values{'DefaultRate'};
    $self->{'CurrencyExchangeLossRate'} = $values{'CurrencyExchangeLossRate'};
    $self->{'FundraisingStatus'} = $values{'FundraisingStatus'};
    $self->{'NetworkAffiliation'} = $values{'NetworkAffiliation'};
    $self->{'EmailContact'} = $values{'EmailContact'};
    $self->{'LoanstoWomenEntrepreneurs'} = $values{'LoanstoWomenEntrepreneurs'};
    $self->{'AverageLoanSize'} = $values{'AverageLoanSize'};
    $self->{'AverageIndividualLoanSize'} = $values{'AverageIndividualLoanSize'};
    $self->{'AverageGroupLoanSize'} = $values{'AverageGroupLoanSize'};
    $self->{'AverageNumberOfEntrepreneursPerGroup'} = $values{'AverageNumberOfEntrepreneursPerGroup'};
    $self->{'AverageGDPPerCapitaPPPinLocalCountry'} = $values{'AverageGDPPerCapitaPPPinLocalCountry'};
    $self->{'AverageLoanSizeGDPPerCapitaPPP'} = $values{'AverageLoanSizeGDPPerCapitaPPP'};
    $self->{'AverageTimeToFundALoan'} = $values{'AverageTimeToFundALoan'};
    $self->{'AverageDollarsRaisedPerDayPerLoan'} = $values{'AverageDollarsRaisedPerDayPerLoan'};
    $self->{'AverageLoanTerm'} = $values{'AverageLoanTerm'};
    $self->{'TotalJournals'} = $values{'TotalJournals'};
    $self->{'JournalCoverage'} = $values{'JournalCoverage'};
    $self->{'JournalCoverageKivaFellows'} = $values{'JournalCoverageKivaFellows'};
    $self->{'JournalFrequencyAveragePerLoanPerYear'} = $values{'JournalFrequencyAveragePerLoanPerYear'};
    $self->{'AverageNumberOfRecommendationsPerJournal'} = $values{'AverageNumberOfRecommendationsPerJournal'};
    $self->{'AverageInterestRateBorrowerPaysToKivaFieldPartner'} = $values{'AverageInterestRateBorrowerPaysToKivaFieldPartner'};
    $self->{'AverageLocalMoneyLenderInterestRate'} = $values{'AverageLocalMoneyLenderInterestRate'};

    $self->{'id'} = $url;
    $self->{'url'} = $tld."about/aboutPartner?id=$url";

#    for my $k (sort keys %$self){print "$k - ".($$self{$k} || ""),"\n";}


    $tree->destroy;
    bless $self, $pkg;
    return $self;
}

sub is_different{
    my ($self, $targ) = @_;
    foreach (qw/ id FieldPartnerRiskRating FieldPartner StartDateOnKiva TimeOnKiva KivaEntrepreneurs TotalLoans DelinquencyRate DefaultRate
CurrencyExchangeLossRate FundraisingStatus NetworkAffiliation EmailContact LoanstoWomenEntrepreneurs AverageLoanSize AverageIndividualLoanSize
 AverageGroupLoanSize
AverageNumberOfEntrepreneursPerGroup AverageGDPPerCapitaPPPinLocalCountry AverageLoanSizeGDPPerCapitaPPP AverageTimeToFundALoan
AverageDollarsRaisedPerDayPerLoan AverageLoanTerm TotalJournals JournalCoverage JournalCoverageKivaFellows JournalFrequencyAveragePerLoanPerYear
	     AverageNumberOfRecommendationsPerJournal AverageInterestRateBorrowerPaysToKivaFieldPartner AverageLocalMoneyLenderInterestRate/){
	return 1 if ($self->{$_} ne $targ->{$_});
    }
    return undef;
}

sub to_string{
    my ($self) = @_;
    my @ret = ();
    foreach (qw/ id FieldPartnerRiskRating FieldPartner StartDateOnKiva TimeOnKiva KivaEntrepreneurs TotalLoans DelinquencyRate DefaultRate 
CurrencyExchangeLossRate FundraisingStatus NetworkAffiliation EmailContact LoanstoWomenEntrepreneurs AverageLoanSize AverageIndividualLoanSize
 AverageGroupLoanSize
AverageNumberOfEntrepreneursPerGroup AverageGDPPerCapitaPPPinLocalCountry AverageLoanSizeGDPPerCapitaPPP AverageTimeToFundALoan
AverageDollarsRaisedPerDayPerLoan AverageLoanTerm TotalJournals JournalCoverage JournalCoverageKivaFellows JournalFrequencyAveragePerLoanPerYear
AverageNumberOfRecommendationsPerJournal AverageInterestRateBorrowerPaysToKivaFieldPartner AverageLocalMoneyLenderInterestRate/){
	    push @ret, ($self->{$_}?$self->{$_}:"");
#	    printf("%s - %s\n", $_, $self->{$_});
    }
    return join("\t",@ret);
}


sub new_from_url{
    my ($pkg, $url) = @_;
    return undef unless $url;
    my $self = {};
    my $ua = new LWP::UserAgent();
    my $res = $ua->get($tld.$url);
    if (!$res->is_success){
	print "Warning: unable to retrieve page: $tld$url\nStatus: ".$res->status_line."\n";
	return undef;
    }
    print "KivaPart Fetched: $tld$url\n";
    print "Status: ".$res->status_line."\n";
    my $tree = HTML::TreeBuilder->new_from_content($res->content);
    my @stats = $tree->look_down("_tag" => "div", "class" => "kvInfoBox");
    return undef unless (@stats > 0);

    my %values = ();
    for my $data (@stats){
	for my $nvp ($data->look_down("_tag"=>"tr")){
#	print $nvp->as_HTML(),"\n";
	    my @conts = $nvp->content_list();
	    while ((@conts > 1) && (!compress(clean($conts[0]->as_trimmed_text())) || compress(clean($conts[0]->as_trimmed_text())) eq "")){ shift @conts;}
	    next if (@conts < 2);
	    my $label = $conts[0]->as_trimmed_text();
	    my $value = $conts[1]->as_trimmed_text();
	    $label =~ s/\W//g;
	    $values{clean($label)} =  clean($value);
#	$values{clean($tmp[0])} =clean($tmp[1]) if $tmp[0] =~ /Loan/;
	    $values{clean($label)} =  clean($conts[1]->as_HTML()) if ($label =~ /Risk\s?Rating/);
	    printf("Values: %s - %s\n", $label, $value);
	}
    }

    $self->{'FieldPartnerRiskRating'} += () = $values{'FieldPartnerRiskRating'} =~ /(on_small)/g; 
#counting the number of stars on_small vs off_small

    $self->{'FieldPartner'} = $values{'FieldPartner'};
    $self->{'StartDateOnKiva'} = $values{'StartDateOnKiva'};
    $self->{'TimeOnKiva'} = $values{'TimeOnKiva'};
    $self->{'KivaEntrepreneurs'} = $values{'KivaEntrepreneurs'};
    $self->{'TotalLoans'} = fixnumeric($values{'TotalLoans'});
    $self->{'DelinquencyRate'} = fixnumeric($values{'DelinquencyRate'});
    $self->{'DefaultRate'} = fixnumeric($values{'DefaultRate'});
    $self->{'CurrencyExchangeLossRate'} = $values{'CurrencyExchangeLossRate'};
    $self->{'FundraisingStatus'} = $values{'FundraisingStatus'};
    $self->{'NetworkAffiliation'} = $values{'NetworkAffiliation'};
    $self->{'EmailContact'} = $values{'EmailContact'};
    $self->{'LoanstoWomenEntrepreneurs'} = $values{'LoanstoWomenEntrepreneurs'};
    $self->{'AverageLoanSize'} = $values{'AverageLoanSize'};
    $self->{'AverageIndividualLoanSize'} = $values{'AverageIndividualLoanSize'};
    $self->{'AverageGroupLoanSize'} = $values{'AverageGroupLoanSize'};
    $self->{'AverageNumberOfEntrepreneursPerGroup'} = $values{'AverageNumberOfEntrepreneursPerGroup'};
    $self->{'AverageGDPPerCapitaPPPinLocalCountry'} = $values{'AverageGDPPerCapitaPPPinLocalCountry'};
    $self->{'AverageLoanSizeGDPPerCapitaPPP'} = $values{'AverageLoanSizeGDPPerCapitaPPP'};
    $self->{'AverageTimeToFundALoan'} = $values{'AverageTimeToFundALoan'};
    $self->{'AverageDollarsRaisedPerDayPerLoan'} = $values{'AverageDollarsRaisedPerDayPerLoan'};
    $self->{'AverageLoanTerm'} = $values{'AverageLoanTerm'};
    $self->{'TotalJournals'} = fixnumeric($values{'TotalJournals'});
    $self->{'JournalCoverage'} = $values{'JournalCoverage'};
    $self->{'JournalCoverageKivaFellows'} = $values{'JournalCoverageKivaFellows'};
    $self->{'JournalFrequencyAveragePerLoanPerYear'} = $values{'JournalFrequencyAveragePerLoanPerYear'};
    $self->{'AverageNumberOfRecommendationsPerJournal'} = $values{'AverageNumberOfRecommendationsPerJournal'};
    $self->{'AverageInterestRateBorrowerPaysToKivaFieldPartner'} = $values{'AverageInterestRateBorrowerPaysToKivaFieldPartner'};
    $self->{'AverageLocalMoneyLenderInterestRate'} = $values{'AverageLocalMoneyLenderInterestRate'};

    $self->{'id'} = (split(/=/, $url))[-1];
    $self->{'url'} = $tld.$url;

#    for my $k (sort keys %$self){print "$k - ".($$self{$k} || ""),"\n";}


    $tree->destroy;
    bless $self, $pkg;
    return $self;
}

#to ensure that the delimiting character is not in any field we present to the CSV file
sub clean{
    my $str = shift;
    return undef unless $str;
    $str =~ s/^\s+//g;
    $str =~ s/\s+$//g;
    $str =~ s/\s+/ /g;
    $str =~ s/\t//g;
    return $str;
}

sub compress{
  my $str = shift;
  return undef unless $str;
   $str =~ s/\W//g;
  return $str;
}

sub fixnumeric{
  my $str = shift;
  return undef unless $str;
  $str =~ s/[\$\%,]//g;
  return $str;
}

sub getId{
    my $self = shift;
    return $self->{'id'};
}

1;
