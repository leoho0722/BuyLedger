import * as fs from 'node:fs';
import * as path from 'node:path';

import {
  MissingFieldClockError,
  mergeFieldWrites,
} from './apply-field-writes';

const vectorsPath = path.join(
  __dirname,
  '../../../../shared/sync-conformance/field-merge-vectors.json',
);
const vectors = JSON.parse(fs.readFileSync(vectorsPath, 'utf8'));

describe('mergeFieldWrites conformance vectors', () => {
  for (const c of vectors.cases) {
    it(c.name, () => {
      const result = mergeFieldWrites(c.storedValues, c.storedClocks, c.patch);
      expect(result.values).toEqual(c.expectedValues);
      expect(result.appliedClocks).toEqual(c.expectedAppliedClocks);
      if (typeof c.expectedChanged === 'boolean') {
        expect(result.changed).toBe(c.expectedChanged);
      }
    });
  }
});

describe('mergeFieldWrites edge behavior', () => {
  it('throws MissingFieldClockError when a changed field has no clock', () => {
    expect(() =>
      mergeFieldWrites(
        {},
        {},
        { changedFields: { amount: '10' }, fieldClocks: {} },
      ),
    ).toThrow(MissingFieldClockError);
  });

  it('does not mutate the stored inputs', () => {
    const storedValues = { amount: '100' };
    const storedClocks = { amount: '1700000000000:000000:device-a' };
    mergeFieldWrites(storedValues, storedClocks, {
      changedFields: { amount: '200' },
      fieldClocks: { amount: '1700000000005:000000:device-b' },
    });
    expect(storedValues).toEqual({ amount: '100' });
    expect(storedClocks).toEqual({ amount: '1700000000000:000000:device-a' });
  });

  it('leaves untouched stored fields intact', () => {
    const result = mergeFieldWrites(
      { customerName: '王', amount: '100', notes: 'x' },
      {
        customerName: '1700000000000:000000:device-a',
        amount: '1700000000000:000000:device-a',
        notes: '1700000000000:000000:device-a',
      },
      {
        changedFields: { amount: '200' },
        fieldClocks: { amount: '1700000000005:000000:device-b' },
      },
    );
    expect(result.values.customerName).toBe('王');
    expect(result.values.notes).toBe('x');
    expect(result.clocks.customerName).toBe('1700000000000:000000:device-a');
  });
});
