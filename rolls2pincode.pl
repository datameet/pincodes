#!/usr/bin/perl

#
# rolls2pincode.pl
#
# This quick and dirty hack extracts the pincode for each polling booth from the front pages of India's electoral rolls. 
# It expects the following folder structure: <SERVER>/Voter-List-2014/<AC>/<AC>-<BOOTH>.pdf
# The outcome is an sqlite file (and manual csv dump later on) with state, ac, booth, pincode columns.
# Since it uses the 2014 revision of electoral rolls, this table can be merged with GIS data from http://dx.doi.org/10.4119/unibi/2674065
# Beware that rolls in some states don't have pincodes, or don't have them in extractable latin script - these will have NULL values then. 
# Besides DNH and Lakshadweep which probably are too small, this affects three larger states: Kerala, Punjab and Rajasthan.
#
# Otherwise all should be fine - still: no guarantees
# Questions and comments to Raphael Susewind, mail@raphael-susewind.de
#

use DBI;
use utf8;

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});

$dbh->do("CREATE TABLE rolls2pincode (state CHAR, ac INTEGER, booth INTEGER, pincode INTEGER)");

my @files = `find . -name '*pdf'`;
my %done;

foreach my $file (@files) {
    chomp ($file);
    next if $file !~ /\/Voter-List-2014\//;
    next if $file =~ /Supp.pdf/;
    next if $file =~ /Map.pdf/;
    
    $file =~ /^\.\/(.*?)\//;
    my $state = $1;
    
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    
    if ($state eq 'as1.and.nic.in') {$state='Andoman & Nicobar';$file=~/(\d+).pdf/;$booth=$1;$ac=1;}
    elsif ($state eq 'ceoandhra.nic.in') {$state='Andhra Pradesh';}
    elsif ($state eq 'ceoarunachal.nic.in') {$state='Arunachal Pradesh';}
    elsif ($state eq 'ceoassam.nic.in') {$state='Assam';}
    elsif ($state eq 'ceobihar.nic.in') {$state='Bihar';}
    elsif ($state eq 'ceochandigarh.nic.in') {$state='Chandigarh';$file=~/(\d+).pdf/;$booth=$1;$ac=1;}
    elsif ($state eq 'ceodaman.nic.in') {$state='Daman & Diu';$file=~/(\d+)-.*?.pdf/;$booth=$1;$ac=1;}
    elsif ($state eq 'ceodelhi.gov.in') {$state='Delhi';}
    elsif ($state eq 'ceodnh.nic.in') {$state='Dadra & Nagar Haveli';$file=~/(\d+)-.*?.pdf/;$booth=$1;$ac=1;}
    elsif ($state eq 'ceogoa.nic.in') {$state='Goa';}
    elsif ($state eq 'ceogujarat.nic.in') {$state='Gujarat';}
    elsif ($state eq 'ceoharyana.nic.in') {$state='Haryana';}
    elsif ($state eq 'ceohimachal.nic.in') {$state='Himachal Pradesh';}
    elsif ($state eq 'ceojk.nic.in') {$state='Jammu & Kashmir';}
    elsif ($state eq 'ceokarnataka.kar.nic.in') {$state='Karnataka';}
    elsif ($state eq 'ceo.kerala.gov.in') {$state='Kerala';}
    elsif ($state eq 'ceolakshadweep.gov.in') {$state='Lakshadweep';$file=~/(\d+).pdf/;$booth=$1;$ac=1;}
    elsif ($state eq 'ceomadhyapradesh.nic.in') {$state='Madhya Pradesh';}
    elsif ($state eq 'ceo.maharashtra.gov.in') {$state='Maharashtra';}
    elsif ($state eq 'ceomanipur.nic.in') {$state='Manipur';}
    elsif ($state eq 'ceomeghalaya.nic.in') {$state='Meghalaya';}
    elsif ($state eq 'ceomizoram.nic.in') {$state='Mizoram';}
    elsif ($state eq 'ceonagaland.nic.in') {$state='Nagaland';}
    elsif ($state eq 'ceoorissa.nic.in') {$state='Orissa';}
    elsif ($state eq 'ceopondicherry.nic.in') {$state='Pondicherry';}
    elsif ($state eq 'ceopunjab.nic.in') {$state='Punjab';}
    elsif ($state eq 'ceorajasthan.nic.in') {$state='Rajasthan';}
    elsif ($state eq 'ceosikkim.nic.in') {$state='Sikkim';}
    elsif ($state eq 'ceotripura.nic.in') {$state='Tripura';}
    elsif ($state eq 'ceo.uk.gov.in') {$state='Uttarakhand';}
    elsif ($state eq 'ceouttarpradesh.nic.in') {$state='Uttar Pradesh';}
    elsif ($state eq 'ceowestbengal.nic.in') {$state='West Bengal';}
    elsif ($state eq 'cg.nic.in') {$state='Chhattisgarh';}
    elsif ($state eq 'elections.tn.gov.in') {$state='Tamil Nadu';}
    elsif ($state eq 'jharkhand.gov.in') {$state='Jharkhand';}

    if (defined($done{$state.'-'.$ac.'-'.$booth})) {next;} else {$done{$state.'-'.$ac.'-'.$booth}=1}

    my $frontpage = `pdftotext -f 1 -l 1 -nopgbrk $file -`;
    $frontpage =~ /(\d\d\d\d\d\d)/gs;
    my $pincode = $1;
    if ($pincode !~ /\d\d\d\d\d\d/) {undef($pincode)}
    
    $dbh->do("INSERT INTO rolls2pincode VALUES (?,?,?,?)",undef,$state,$ac,$booth,$pincode);
}

$dbh->sqlite_backup_to_file("rolls2pincode.sqlite");
$dbh->disconnect;
