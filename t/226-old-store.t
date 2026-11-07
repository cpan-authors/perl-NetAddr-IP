#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( lives );
use Test2::Tools::Warnings  qw( warnings );

SKIP: {
    skip 'Storable not available'
        unless eval { require Storable; Storable->import(qw(freeze thaw)); 1; };

    skip 'NetAddr::IP not available'
        unless eval { require NetAddr::IP; 1; };

    my $import_warnings = warnings { NetAddr::IP->import(':old_storable') };

    subtest 'importing :old_storable warns that it is deprecated' => sub {
        is( scalar @{$import_warnings}, 1, 'the import warns once' );
        like(
            $import_warnings->[0],
qr/^:old_storable is deprecated and will be removed in version 5; without it Storable freezes an object as its CIDR text, and data frozen as a plain hash still thaws at /,
            'the warning names the tag and what Storable does without it'
        );
    };

    subtest 'old storable round-trip' => sub {
        my $oip = NetAddr::IP->new('localhost');
        isa_ok( $oip, ['NetAddr::IP'], 'Correct return type' );

        my $serialized;
        ok( lives { $serialized = freeze($oip) }, 'Freezing' );
        ok( length($serialized) > 0,              'Serialized data is not empty' );

        my $nip;
        ok( lives { $nip = thaw($serialized) }, 'Thawing' );

        isa_ok( $nip, ['NetAddr::IP'], 'Recovered correct type' );
        is( "$nip", "$oip", 'New object eq original object' );

        # Old format uses full hash serialization (not CIDR string)
        unlike(
            $serialized, qr|/|,
            'Old format does not contain CIDR notation'
        );
        like( $serialized, qr/NetAddr::IP/, 'Old format contains class name' );
    };

    subtest ':old_storable is sticky - hooks stay removed' => sub {

        # Test that once hooks are removed with :old_storable, they stay removed
        # even if we call import() again without :old_storable
        ok( !NetAddr::IP->can('STORABLE_freeze'),
            'hooks initially removed after :old_storable'
        );
        ok( !NetAddr::IP->can('STORABLE_thaw'),
            'hooks initially removed after :old_storable'
        );

        # Call import again without :old_storable - hooks should STAY removed (sticky)
        NetAddr::IP->import();
        ok( !NetAddr::IP->can('STORABLE_freeze'),
            'hooks stay removed after import() without :old_storable'
        );
        ok( !NetAddr::IP->can('STORABLE_thaw'),
            'hooks stay removed after import() without :old_storable'
        );
    };

    subtest 'require vs use consistency with :old_storable' => sub {

        # Verify both require+import and use can trigger :old_storable
        ok( !NetAddr::IP->can('STORABLE_freeze'), 'hooks currently removed' );

        # Calling import again without :old_storable should NOT reinstall hooks
        NetAddr::IP->import();
        ok( !NetAddr::IP->can('STORABLE_freeze'),
            'hooks stay removed after import()'
        );
        ok( !NetAddr::IP->can('STORABLE_thaw'),
            'hooks stay removed after import()'
        );

        # Verify the old format still works
        my $oip        = NetAddr::IP->new('localhost');
        my $serialized = freeze($oip);
        my $nip        = thaw($serialized);
        is( "$nip", "$oip",
            'Old format round-trip still works after multiple imports'
        );
    };
}

done_testing;

