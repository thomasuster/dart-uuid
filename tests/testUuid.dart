#import("package:unittest/unittest.dart");
#import('../Uuid.dart'); 
#import('dart:math', prefix:"Math");

main() {
  var uuid = new Uuid();
  final int TIME = 1321644961388;

  List mathRNGCustom() {
    var rand, b = new List(16);

    var _rand = new Math.Random(1);
    for(var i = 0; i < 16; i++) {
      if ((i & 0x03) == 0) {
        rand = (_rand.nextDouble() * 0x100000000).floor().toInt();
      }
      b[i] = rand >> ((i & 0x03) << 3) & 0xff;
    }

    return b;
  }
  
  group('[Version 1 Tests]', () {
    test('IDs created at same mSec are different', () {
      expect(uuid.v1({'mSecs': TIME}), isNot(equals(uuid.v1({'mSecs': TIME}))));
    });

    test('Exception thrown when > 10K ids created in 1 ms', () {
      var thrown = false;
      try {
        uuid.v1({'mSecs': TIME, 'nSecs': 10000});
      } catch (e) {
        thrown = true;
      }
      expect(thrown, equals(true));
    });

    test('Clock regression by msec increments the clockseq - mSec', () {
      var uidt = uuid.v1({'mSecs': TIME});
      var uidtb = uuid.v1({'mSecs': TIME - 1});

      expect((Math.parseInt("0x${uidtb.split('-')[3]}")
          - Math.parseInt("0x${uidt.split('-')[3]}")), anyOf(equals(1), equals(-16383)));
    });

    test('Clock regression by msec increments the clockseq - nSec', () {
      var uidt = uuid.v1({'mSecs': TIME, 'nSecs': 10});
      var uidtb = uuid.v1({'mSecs': TIME, 'nSecs': 9});

      expect((Math.parseInt("0x${uidtb.split('-')[3]}")
          - Math.parseInt("0x${uidt.split('-')[3]}")), equals(1));
    });

    test('Explicit options produce expected id', () {
      var id = uuid.v1({
        'mSecs': 1321651533573,
        'nSecs': 5432,
        'clockSeq': 0x385c,
        'node': [ 0x61, 0xcd, 0x3c, 0xbb, 0x32, 0x10 ]
      });

      expect(id, equals('d9428888-122b-11e1-b85c-61cd3cbb3210'));
    });

    test('Ids spanning 1ms boundary are 100ns apart', () {
      var u0 = uuid.v1({'mSecs': TIME, 'nSecs': 9999});
      var u1 = uuid.v1({'mSecs': TIME + 1, 'nSecs': 0});

      var before = u0.split('-')[0], after = u1.split('-')[0];
      var dt = Math.parseInt('0x$after') - Math.parseInt('0x$before');

      expect(dt, equals(1));
    });
  });
  
  group('[Version 4 Tests]', () {
    test('Check if V4 is consistent using a static seed', () {
      var u0 = uuid.v4({
        'rng': mathRNGCustom()
      });
      var u1 = "0fc6a4b0-914e-439b-83cc-d57c8a731749";
      expect(u0, equals(u1));
    });
    
    test('Return same output as entered for "random" option', () {
      var u0 = uuid.v4({
        'random': [
                   0x10, 0x91, 0x56, 0xbe, 0xc4, 0xfb, 0xc1, 0xea,
                   0x71, 0xb4, 0xef, 0xe1, 0x67, 0x1c, 0x58, 0x36
                   ]
      });
      var u1 = "109156be-c4fb-41ea-b1b4-efe1671c5836";
      expect(u0, equals(u1));
    });
  });
  
  group('[Version 5 Tests]', () {
    test('Using URL namespace and custom name', () {
      var u0 = uuid.v5(uuid.NAMESPACE_URL, 'www.google.com');
      var u1 = uuid.v5(uuid.NAMESPACE_URL, 'www.google.com');
      
      expect(u0, equals(u1));
    });
    
    test('Using Random namespace and custom name', () {
      var u0 = uuid.v5(null, 'www.google.com');
      var u1 = uuid.v5(null, 'www.google.com');
      
      expect(u0, isNot(equals(u1)));
    });
  });
  
  group('[Parse/Unparse Tests]', () {
    test('Parsing a short/cut-off UUID', () {
      var id = '00112233445566778899aabbccddeeff';
      expect(uuid.unparse(uuid.parse(id.substring(0,10))),
        equals('00112233-4400-0000-0000-000000000000'));
    });

    test('Parsing a dirty string with a UUID in it', () {
      var id = '00112233445566778899aabbccddeeff';
      expect(uuid.unparse(uuid.parse('(this is the uuid -> $id$id')),
        equals('00112233-4455-6677-8899-aabbccddeeff'));
    }); // Temporarily turn off until String.split() is fixed */
  });
}
