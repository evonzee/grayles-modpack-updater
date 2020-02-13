#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use File::Copy;
use FileHandle;
use IPC::Run3;
use Text::CSV;

sub main() {
    print "Would load mods here\n";
    # read mods CSV
    my @rows = readCsv();
    print "Read " . $#rows . " CSV rows..\n";


    my @steamDownloads = ();

    # Loop each row
    foreach my $rowRef (@rows){
        my @row = @$rowRef;
        print "Inspecting row @row...";

        # if it has a steam url, add it to the steam list
        if ($row[6] =~ /steamcomm/i) {
            push(@steamDownloads, prepareSteam($row[6], \@row));
        }
        if ($row[7] =~ /steamcomm/i) {
            push(@steamDownloads, prepareSteam($row[7], \@row));
        }

        # if it has a starbound forum link
            # check if there's an update?

        print "\n";
    }

    #debug: see what we got
    #print Dumper(\@steamDownloads);

    #write the steamcmd instructions and download with steamcmd
    downloadSteam(\@steamDownloads);

    #download with steamcmd
   
        
    # write a new modpack csv with versioning if possible
        

}


sub readCsv(){
    my $file = "current-modpack.csv";
    my $csv = Text::CSV->new({ 
        sep_char    => ',', 
        auto_diag   => 2, 
        binary      => 1,
    });

    my @rows = [];

    open(my $data, '<', $file) or die "Could not open '$file' $!\n";
    while (my $line = <$data>) {
        chomp $line;
        $line =~ s/\r//g;

        if ($csv->parse($line)) {

            my @fields = $csv->fields();
            push @rows, \@fields

        } else {
            warn "Line could not be parsed: $line\n";
        }
    }
    return @rows;

}

sub prepareSteam() {
    my $url = shift;
    my @row = @{shift()};
    print "Found a Steam URL...";

    $url =~ m/id=(\d+)/;
    my $id =$1;

    my $info = {
        "id" => $id,
        "name" => $row[0],
        "url" => $url,
    };
    return $info;
}

sub downloadSteam() {
    my @downloads = @{ shift() };
    print "Bootstrapping steamcmd...\n\n";


    my @bootstrap = ["./steamcmd.sh","+quit"];
    run3( @bootstrap );

    print "\n\nBootstrap complete.  Preparing to download workshop mods\n";

    print "Since Starbound won't let you download workshop mods unless you own the game, please enter your Steam login\n";
    my $login = <STDIN>;
    print "and your password? If you don't trust me, I get it.  But check out the source code for this program.. I'm not doing anything malicous.\n";
    my $password = <STDIN>;
    print "and finally, the current code from your Steam Lock if you use it?\n";
    my $key = <STDIN>;
    
    chomp($login);
    chomp($password);
    chomp($key);

    my @processed = ();

    my $fh = FileHandle->new;
    if($fh->open(">/tmp/sc-script")) {

        print $fh "\@ShutdownOnFailedCommand 1\n";
        print $fh "login $login $password $key\n";
        print $fh "force_install_dir /tmp \n";

        foreach my $item (@downloads) {
            my $id = $item->{id};
            if($id == ""){
                print "Invalid ID on mod " . $item->{name} . ", skipping\n";
            } else {
                print $fh "workshop_download_item 211820 $id\n";
                push(@processed, $item);
            }
        }
        print $fh "quit\n";
        $fh->close();

    } else {
        die "Could not write steamcmd script!";
    }

    #print "\n\n\nDebug: Script to run:\n";
    #$fh->open("</tmp/sc-script");
    #while (my $line = <$fh>){
    #    print $line;
    #}
    #print "\n\n\n";

    print "Calling steamcmd...\n";
    my @command = ["./steamcmd.sh","+runscript","/tmp/sc-script"];
    run3( @command );
    print "Done with steamcmd.\n";
    unlink "/tmp/sc-script";

    print "Copying mods to output folder and renaming...";
    foreach my $item (@processed) {
        my $id = $item->{id};
        my $name = $item->{name};
        my $startfile = "/tmp/steamapps/workshop/content/211820/$id/content.pak";
        my $endfile = "/mods/$name.pak";
        copy($startfile, $endfile);
    }

}


main();