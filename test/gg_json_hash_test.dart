// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_json_hash/src/gg_json_hash.dart';
import 'package:test/test.dart';
import 'example_json.dart';

void main() {
  final calcHash = const JsonHash().calcHash;

  group('JsonHash', () {
    group('with a simple json', () {
      group('containing only one key value pair', () {
        test('with a string value', () {
          final json = addHashes(const {'key': 'value'});
          expect(json['key'], 'value');
          final expectedHash = calcHash('{"key":"value"}');
          expect(json['_hash'], expectedHash);
          expect(json['_hash'], '5Dq88zdSRIOcAS-WM_lYYt');
        });

        test('with a int value', () {
          final json = addHashes(const {'key': 1});
          expect(json['key'], 1);
          final expectedHash = calcHash('{"key":1}');
          expect(json['_hash'], expectedHash);
          expect(json['_hash'], 't4HVsGBJblqznOBwy6IeLt');
        });

        test('with a bool value', () {
          final json = addHashes(const {'key': true});
          expect(json['key'], true);
          final expectedHash = calcHash('{"key":true}');
          expect(json['_hash'], expectedHash);
          expect(json['_hash'], 'dNkCrIe79x2dPyf5fywwYO');
        });

        test('with a long double value', () {
          final json = addHashes(const {'key': 1.0123456789012345});
          final expectedHash = calcHash('{"key":1.0123456789}');
          expect(json['_hash'], expectedHash);
          expect(json['_hash'], 'Cj6IqsbT9fSKfeVVkytoqA');
        });

        test('with a short double value', () {
          final json = addHashes(const {'key': 1.012000});
          final expectedHash = calcHash('{"key":1.012}');
          expect(json['_hash'], expectedHash);
          expect(json['_hash'], 'ppGtYoP5iHFqst5bPeAGMf');
        });
      });

      test('existing _hash should be overwritten', () {
        final json = addHashes({
          'key': 'value',
          '_hash': 'oldHash',
        });
        expect(json['key'], 'value');
        final expectedHash = calcHash('{"key":"value"}');
        expect(json['_hash'], expectedHash);
        expect(json['_hash'], '5Dq88zdSRIOcAS-WM_lYYt');
      });

      group('containing floating point numbers', () {
        test(
            'truncates the floating point numbers to "hashFloatingPrecision" '
            '10 decimal places', () {
          final hash0 = addHashes(
            const {'key': 1.01234567890123456789},
            floatingPointPrecision: 9,
          )['_hash'];

          final hash1 = addHashes(
            const {'key': 1.01234567890123456389},
            floatingPointPrecision: 9,
          )['_hash'];
          final expectedHash = calcHash('{"key":1.012345678}');
          expect(hash0, hash1);
          expect(hash0, expectedHash);
        });
      });

      group('containing three key value pairs', () {
        const json0 = {
          'a': 'value',
          'b': 1.0,
          'c': true,
        };

        const json1 = {
          'b': 1.0,
          'a': 'value',
          'c': true,
        };

        late Map<String, dynamic> j0;
        late Map<String, dynamic> j1;

        setUpAll(() {
          j0 = addHashes(json0);
          j1 = addHashes(json1);
        });

        test('should create a string of key value pairs and hash it', () {
          final expectedHash = calcHash(
            '{"a":"value","b":1.0,"c":true}',
          );

          expect(j0['_hash'], expectedHash);
          expect(j1['_hash'], expectedHash);
        });

        test('should sort work independent of key order', () {
          expect(j0, j1);
          expect(j0['_hash'], j1['_hash']);
          expect(true.toString(), 'true');
        });
      });
    });

    group('with a nested json', () {
      test('of level 1', () {
        // Hash an parent object containing one child object
        final parent = addHashes(const {
          'key': 'value',
          'child': {
            'key': 'value',
          },
        });

        // Check the hash of the child object
        final child = parent['child'] as Map<String, dynamic>;
        final childHash = calcHash('{"key":"value"}');
        expect(child['_hash'], childHash);

        // Check the hash of the top level object
        final parentHash = calcHash(
          '{"child":"$childHash","key":"value"}',
        );

        expect(parent['_hash'], parentHash);
      });

      test('of level 2', () {
        // Hash an parent object containing one child object
        final parent = addHashes(const {
          'key': 'value',
          'child': {
            'key': 'value',
            'grandChild': {
              'key': 'value',
            },
          },
        });

        // Check the hash of the grandChild object
        final grandChild =
            parent['child']!['grandChild'] as Map<String, dynamic>;
        final grandChildHash = calcHash(
          '{"key":"value"}',
        );
        expect(grandChild['_hash'], grandChildHash);

        // Check the hash of the child object
        final child = parent['child'] as Map<String, dynamic>;
        final childHash = calcHash(
          '{"grandChild":"$grandChildHash","key":"value"}',
        );
        expect(child['_hash'], childHash);

        // Check the hash of the top level object
        final parentHash = calcHash(
          '{"child":"$childHash","key":"value"}',
        );
        expect(parent['_hash'], parentHash);
      });
    });

    test('with complete json example', () {
      final json = jsonDecode(exampleJson) as Map<String, dynamic>;
      final hashedJson = addHashes(json);

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      final hashedJsonString = encoder.convert(hashedJson);
      // print(hashedJsonString);
      // return;
      expect(hashedJsonString, exampleJsonWithHashes);
    });

    group('with an array', () {
      group('on top level', () {
        group('containing only simple types', () {
          test('should convert all values to strings and hash it', () {
            final json = addHashes({
              'key': ['value', 1.0, true],
            });

            final expectedHash = calcHash(
              '{"key":["value","1.0","true"]}',
            );

            expect(json['_hash'], expectedHash);
            expect(json['_hash'], '1DJgJ9oBYJWG04HMShLE9o');
          });
        });

        group('containing nested objects', () {
          group('should hash the nested objects', () {
            group('and use the hash instead of the stringified value', () {
              test('with a complicated array', () {
                final json = addHashes({
                  'array': [
                    'key',
                    1.0,
                    true,
                    {'key1': 'value1'},
                    {'key0': 'value0'},
                  ],
                });

                final h0 = calcHash('{"key0":"value0"}');
                final h1 = calcHash('{"key1":"value1"}');
                final expectedHash = calcHash(
                  '{"array":["key","1.0","true","$h1","$h0"]}',
                );

                expect(json['_hash'], expectedHash);
                expect(json['_hash'], 'RhdI6mef3-0PVMG0sdeScv');
              });

              test('with a simple array', () {
                final json = addHashes({
                  'array': [
                    {'key': 'value'},
                  ],
                });

                // Did hash the array item?
                final itemHash = calcHash(
                  '{"key":"value"}',
                );
                final array = json['array'] as List<dynamic>;
                final item0 = array[0] as Map<String, dynamic>;
                expect(item0['_hash'], itemHash);
                expect(
                  itemHash,
                  '5Dq88zdSRIOcAS-WM_lYYt',
                );

                // Did use the array item hash for the array hash?

                final expectedHash = calcHash(
                  '{"array":["$itemHash"]}',
                );

                expect(json['_hash'], expectedHash);
                expect(json['_hash'], 'zYcZBAUGLgR0ygMxi0V5ZT');
              });
            });
          });
        });

        group('containing nested arrays', () {
          test('should hash the nested arrays', () {
            final json = addHashes({
              'array': [
                ['key', 1.0, true],
                'hello',
              ],
            });

            final jsonHash = calcHash(
              '{"array":[["key","1.0","true"],"hello"]}',
            );

            expect(json['_hash'], jsonHash);
            expect(json['_hash'], 'TPZRhkc7IDTK8EftrWmMSw');
          });
        });
      });
    });

    group('throws', () {
      test('when data contains an unsupported type', () {
        late String message;

        try {
          addHashes({
            'key': Exception(),
          });
        } catch (e) {
          message = e.toString();
        }

        expect(
          message,
          'Exception: Unsupported type: _Exception',
        );
      });
    });

    group('private methods', () {
      group('_copyJson', () {
        final copyJson = JsonHash.privateMethods['_copyJson']
            as Map<String, dynamic> Function(Map<String, dynamic>);

        test('empty json', () {
          expect(copyJson(<String, dynamic>{}), <String, dynamic>{});
        });

        test('simple value', () {
          expect(copyJson({'a': 1}), {'a': 1});
        });

        test('nested value', () {
          expect(
            copyJson(
              {
                'a': {'b': 1},
              },
            ),
            {
              'a': {'b': 1},
            },
          );
        });

        test('list value', () {
          expect(
            copyJson(
              {
                'a': [1, 2],
              },
            ),
            {
              'a': [1, 2],
            },
          );
        });

        test('list with list', () {
          expect(
            copyJson(
              {
                'a': [
                  [1, 2],
                ],
              },
            ),
            {
              'a': [
                [1, 2],
              ],
            },
          );
        });

        test('list with map', () {
          expect(
            copyJson(
              {
                'a': [
                  {'b': 1},
                ],
              },
            ),
            {
              'a': [
                {'b': 1},
              ],
            },
          );
        });

        group('throws', () {
          group('on unsupported type', () {
            test('in map', () {
              late String message;
              try {
                copyJson(
                  {
                    'a': Exception(),
                  },
                );
              } catch (e) {
                message = e.toString();
              }

              expect(message, 'Exception: Unsupported type: _Exception');
            });

            test('in list', () {
              late String message;
              try {
                copyJson(
                  {
                    'a': [Exception()],
                  },
                );
              } catch (e) {
                message = e.toString();
              }

              expect(message, 'Exception: Unsupported type: _Exception');
            });
          });
        });
      });

      group('_isBasicType', () {
        final isBasicType =
            JsonHash.privateMethods['_isBasicType'] as bool Function(dynamic);

        test('returns true if type is a basic type', () {
          expect(isBasicType(1), true);
          expect(isBasicType(1.0), true);
          expect(isBasicType('1'), true);
          expect(isBasicType(true), true);
          expect(isBasicType(false), true);
          expect(isBasicType(<String>{}), false);
        });
      });

      group('_truncate(double, precision)', () {
        final toTruncatedString = JsonHash.privateMethods['_truncate'] as double
            Function(double, int);

        test('truncates commas but only if precision exceeds precision', () {
          expect(toTruncatedString(1.23456789, 2), 1.23);
          expect(toTruncatedString(1.23456789, 3), 1.234);
          expect(toTruncatedString(1.23456789, 4), 1.2345);
          expect(toTruncatedString(1.23456789, 5), 1.23456);
          expect(toTruncatedString(1.23456789, 6), 1.234567);
          expect(toTruncatedString(1.23456789, 7), 1.2345678);
          expect(toTruncatedString(1.23456789, 8), 1.23456789);
          expect(toTruncatedString(1.12, 1), 1.1);
          expect(toTruncatedString(1.12, 2), 1.12);
          expect(toTruncatedString(1.12, 3), 1.12);
          expect(toTruncatedString(1.12, 4), 1.12);
        });

        test('does not add additional commas', () {
          expect(toTruncatedString(1.0, 0), 1);
          expect(toTruncatedString(1.0, 1), 1.0);
          expect(toTruncatedString(1.0, 2), 1.0);
          expect(toTruncatedString(1.0, 3), 1.0);
        });
      });

      group('_jsonString(map)', () {
        final jsonString = JsonHash.privateMethods['_jsonString'] as String
            Function(Map<String, dynamic>);

        test('converts a map into a json string', () {
          expect(jsonString({'a': 1}), '{"a":1}');
          expect(jsonString({'a': 'b'}), '{"a":"b"}');
          expect(jsonString({'a': true}), '{"a":true}');
          expect(jsonString({'a': false}), '{"a":false}');
          expect(jsonString({'a': 1.0}), '{"a":1.0}');
          expect(jsonString({'a': 1.0}), '{"a":1.0}');
          expect(
            jsonString({
              'a': [1, 2],
            }),
            '{"a":[1,2]}',
          );
          expect(
            jsonString({
              'a': {'b': 1},
            }),
            '{"a":{"b":1}}',
          );
        });

        test('throws when unsupported type', () {
          late String message;
          try {
            jsonString({'a': Exception()});
          } catch (e) {
            message = e.toString();
          }

          expect(message, 'Exception: Unsupported type: _Exception');
        });
      });
    });

    group('applyToString()', () {
      test('should add the hash to the json string', () {
        const json = '{"key": "value"}';
        final jsonString = const JsonHash().applyToString(json);
        expect(jsonString, '{"key":"value","_hash":"5Dq88zdSRIOcAS-WM_lYYt"}');
      });
    });

    group('with updateExistingHashes', () {
      late Map<String, dynamic> json;

      setUp(() {
        json = {
          'a': {
            '_hash': 'hash_a',
            'b': {
              '_hash': 'hash_b',
              'c': {
                '_hash': 'hash_c',
                'd': 'value',
              },
            },
          },
        };
      });

      bool allHashesChanged() {
        return json['a']!['_hash'] != 'hash_a' &&
            json['a']!['b']!['_hash'] != 'hash_b' &&
            json['a']!['b']!['c']!['_hash'] != 'hash_c';
      }

      bool noHashesChanged() {
        return json['a']!['_hash'] == 'hash_a' &&
            json['a']!['b']!['_hash'] == 'hash_b' &&
            json['a']!['b']!['c']!['_hash'] == 'hash_c';
      }

      List<String> changedHashes() {
        final result = <String>[];
        if (json['a']!['_hash'] != 'hash_a') {
          result.add('a');
        }

        if (json['a']!['b']!['_hash'] != 'hash_b') {
          result.add('b');
        }

        if (json['a']!['b']!['c']!['_hash'] != 'hash_c') {
          result.add('c');
        }

        return result;
      }

      group('true', () {
        test('should recalculate existing hashes', () {
          addHashes(json, updateExistingHashes: true, inPlace: true);
          expect(allHashesChanged(), isTrue);
        });
      });

      group('false', () {
        group('should not recalculate existing hashes', () {
          test('with all objects having hashes', () {
            addHashes(json, updateExistingHashes: false, inPlace: true);
            expect(noHashesChanged(), isTrue);
          });

          test('with parents have no hashes', () {
            json['a']!.remove('_hash');
            addHashes(json, updateExistingHashes: false, inPlace: true);
            expect(changedHashes(), ['a']);

            json['a']!.remove('_hash');
            json['a']['b']!.remove('_hash');
            addHashes(json, updateExistingHashes: false, inPlace: true);
            expect(changedHashes(), ['a', 'b']);
          });
        });
      });
    });

    group('with inPlace', () {
      group('false', () {
        test('does not touch the original object', () {
          final json = {
            'key': 'value',
          };

          final hashedJson = addHashes(json, inPlace: false);
          expect(
            hashedJson,
            {
              'key': 'value',
              '_hash': '5Dq88zdSRIOcAS-WM_lYYt',
            },
          );

          expect(
            json,
            {
              'key': 'value',
            },
          );
        });
      });

      group('true', () {
        test('writes hashes into original json', () {
          final json = {
            'key': 'value',
          };

          final hashedJson = addHashes(json, inPlace: true);
          expect(
            hashedJson,
            {
              'key': 'value',
              '_hash': '5Dq88zdSRIOcAS-WM_lYYt',
            },
          );

          expect(
            json,
            same(hashedJson),
          );
        });
      });
    });

    group('with recursive', () {
      const json = {
        'a': {
          '_hash': 'hash_a',
          'b': {
            '_hash': 'hash_b',
          },
        },
        'b': {
          '_hash': 'hash_a',
          'b': {
            '_hash': 'hash_b',
          },
        },
        '_hash': 'hash_0',
      };

      group('true', () {
        test('should recalculate deeply all hashes', () {
          final result = addHashes(
            json,
            recursive: true,
          );

          // Root as well as child hashes have changed
          expect(result['_hash'], isNot('hash_0'));
          expect(result['a']!['_hash'], isNot('hash_a'));
          expect(result['a']!['b']!['_hash'], isNot('hash_b'));
        });
      });

      group('false', () {
        test('should only calc the first hash', () {
          final result = addHashes(
            json,
            recursive: false,
          );

          // Root hash has changed
          expect(result['_hash'], isNot('hash_0'));

          // Child hashes have not changed
          expect(result['a']!['_hash'], 'hash_a');
          expect(result['a']!['b']!['_hash'], 'hash_b');
        });
      });

      group('validate', () {
        group('with an empty json', () {
          group('throws', () {
            test('when no hash is given', () {
              late final String message;

              try {
                JsonHash.validate({});
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                'Exception: Hash is missing.',
              );
            });

            test('when hash is wrong', () {
              late final String message;

              try {
                JsonHash.validate({
                  '_hash': 'wrongHash',
                });
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                'Exception: Hash "wrongHash" is wrong. '
                'Should be "RBNvo1WzZ4oRRq0W9-hknp".',
              );
            });
          });

          group('does not throw', () {
            test('when hash is correct', () {
              JsonHash.validate({
                '_hash': 'RBNvo1WzZ4oRRq0W9-hknp',
              });
            });
          });
        });

        group('with an single level json', () {
          group('throws', () {
            test('when no hash is given', () {
              late final String message;

              try {
                JsonHash.validate({'key': 'value'});
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                'Exception: Hash is missing.',
              );
            });

            test('when hash is wrong', () {
              late final String message;

              try {
                JsonHash.validate({
                  'key': 'value',
                  '_hash': 'wrongHash',
                });
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                'Exception: Hash "wrongHash" is wrong. '
                'Should be "5Dq88zdSRIOcAS-WM_lYYt".',
              );
            });
          });

          group('does not throw', () {
            test('when hash is correct', () {
              JsonHash.validate({
                'key': 'value',
                '_hash': '5Dq88zdSRIOcAS-WM_lYYt',
              });
            });
          });
        });

        group('with an deeply nested json', () {
          late Map<String, dynamic> json;

          setUp(
            () {
              json = <String, dynamic>{
                '_hash': 'oEE88mHZ241BRlAfyG8n9X',
                'parent': {
                  '_hash': '3Wizz29YgTIc1LRaN9fNfK',
                  'child': {
                    'key': 'value',
                    '_hash': '5Dq88zdSRIOcAS-WM_lYYt',
                  },
                },
              };
            },
          );

          group('throws', () {
            group('when no hash is given', () {
              test('at the root', () {
                late final String message;
                json.remove('_hash');

                try {
                  JsonHash.validate(json);
                } catch (e) {
                  message = e.toString();
                }

                expect(
                  message,
                  'Exception: Hash is missing.',
                );
              });

              test('at the parent', () {
                late final String message;
                json['parent']!.remove('_hash');

                try {
                  JsonHash.validate(json);
                } catch (e) {
                  message = e.toString();
                }

                expect(
                  message,
                  'Exception: Hash at /parent is missing.',
                );
              });

              test('at the child', () {
                late final String message;
                json['parent']!['child'].remove('_hash');

                try {
                  JsonHash.validate(json);
                } catch (e) {
                  message = e.toString();
                }

                expect(
                  message,
                  'Exception: Hash at /parent/child is missing.',
                );
              });
            });

            group('when hash is wrong', () {
              test('at the root', () {
                late final String message;
                json['_hash'] = 'wrongHash';

                try {
                  JsonHash.validate(json);
                } catch (e) {
                  message = e.toString();
                }

                expect(
                  message,
                  'Exception: Hash "wrongHash" is wrong. '
                  'Should be "oEE88mHZ241BRlAfyG8n9X".',
                );
              });

              test('at the parent', () {
                late final String message;
                json['parent']!['_hash'] = 'wrongHash';

                try {
                  JsonHash.validate(json);
                } catch (e) {
                  message = e.toString();
                }

                expect(
                  message,
                  'Exception: Hash at /parent "wrongHash" is wrong. '
                  'Should be "3Wizz29YgTIc1LRaN9fNfK".',
                );
              });

              test('at the child', () {
                late final String message;
                json['parent']!['child']!['_hash'] = 'wrongHash';

                try {
                  JsonHash.validate(json);
                } catch (e) {
                  message = e.toString();
                }

                expect(
                  message,
                  'Exception: Hash at /parent/child "wrongHash" is wrong. '
                  'Should be "5Dq88zdSRIOcAS-WM_lYYt".',
                );
              });
            });

            group('not', () {
              test('when hash is correct', () {
                JsonHash.validate(json);
              });
            });
          });
        });

        group('with an deeply nested json with child array', () {
          late Map<String, dynamic> json;

          setUp(
            () {
              json = <String, dynamic>{
                '_hash': 'IoJ_C8gm8uVu8ExpS7ZNPY',
                'parent': [
                  {
                    '_hash': 'kDsVfUjnkXU7_KXqp-PuyA',
                    'child': [
                      {'key': 'value', '_hash': '5Dq88zdSRIOcAS-WM_lYYt'},
                    ],
                  }
                ],
              };
            },
          );

          group('throws', () {
            group('when no hash is given', () {
              test('at the parent', () {
                late final String message;
                json['parent']![0].remove('_hash');

                try {
                  JsonHash.validate(json);
                } catch (e) {
                  message = e.toString();
                }

                expect(
                  message,
                  'Exception: Hash at /parent/0 is missing.',
                );
              });

              test('at the child', () {
                late final String message;
                json['parent']![0]['child'][0].remove('_hash');

                try {
                  JsonHash.validate(json);
                } catch (e) {
                  message = e.toString();
                }

                expect(
                  message,
                  'Exception: Hash at /parent/0/child/0 is missing.',
                );
              });
            });

            group('when hash is wrong', () {
              test('at the parent', () {
                late final String message;
                json['parent']![0]['_hash'] = 'wrongHash';

                try {
                  JsonHash.validate(json);
                } catch (e) {
                  message = e.toString();
                }

                expect(
                  message,
                  'Exception: Hash at /parent/0 "wrongHash" is wrong. '
                  'Should be "kDsVfUjnkXU7_KXqp-PuyA".',
                );
              });

              test('at the child', () {
                late final String message;
                json['parent']![0]['child']![0]['_hash'] = 'wrongHash';

                try {
                  JsonHash.validate(json);
                } catch (e) {
                  message = e.toString();
                }

                expect(
                  message,
                  'Exception: Hash at /parent/0/child/0 "wrongHash" is wrong. '
                  'Should be "5Dq88zdSRIOcAS-WM_lYYt".',
                );
              });
            });

            group('not', () {
              test('when hash is correct', () {
                JsonHash.validate(json);
              });
            });
          });
        });
      });
    });
  });
}
