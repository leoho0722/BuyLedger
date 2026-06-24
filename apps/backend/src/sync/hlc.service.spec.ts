import * as fs from 'node:fs';
import * as path from 'node:path';

import { NowService } from '../common/now.service';
import {
  Hlc,
  compareHlc,
  decodeHlc,
  encodeHlc,
  generateHlc,
  isWithinSkewTolerance,
  receiveHlc,
} from './hlc';
import { HlcService } from './hlc.service';

// 跨平台 conformance vectors 的唯一來源 (backend/web/iOS 共用同一檔)
const vectorsPath = path.join(
  __dirname,
  '../../../../shared/sync-conformance/hlc-vectors.json',
);
const vectors = JSON.parse(fs.readFileSync(vectorsPath, 'utf8'));

describe('HLC conformance vectors', () => {
  it('encodes to the sortable p(13):c(6):w form', () => {
    for (const v of vectors.encode) {
      expect(encodeHlc(v.hlc)).toBe(v.expected);
    }
  });

  it('decode is the inverse of encode', () => {
    for (const v of vectors.encode) {
      expect(decodeHlc(v.expected)).toEqual(v.hlc);
    }
  });

  it('compares by p then c then w', () => {
    for (const v of vectors.compare) {
      expect(Math.sign(compareHlc(v.a, v.b))).toBe(v.expected);
    }
  });

  it('encoded byte order matches causal order', () => {
    for (const v of vectors.compare) {
      const ea = encodeHlc(v.a);
      const eb = encodeHlc(v.b);
      const lex = ea < eb ? -1 : ea > eb ? 1 : 0;
      expect(lex).toBe(v.expected);
    }
  });

  it('generates the next local clock', () => {
    for (const v of vectors.generate) {
      expect(generateHlc(v.lastIssued, v.nowMs, v.writerId)).toEqual(v.expected);
    }
  });

  it('receives a remote clock with the HLC merge rule', () => {
    for (const v of vectors.receive) {
      expect(receiveHlc(v.lastIssued, v.remote, v.nowMs, v.writerId)).toEqual(
        v.expected,
      );
    }
  });

  it('flags out-of-tolerance future clocks', () => {
    for (const v of vectors.tolerance) {
      expect(isWithinSkewTolerance(v.remoteP, v.nowMs, v.toleranceMs)).toBe(
        v.expected,
      );
    }
  });
});

describe('HlcService', () => {
  function make(fixedIso: string): HlcService {
    process.env.BUYLEDGER_FIXED_NOW = fixedIso;
    return new HlcService(new NowService());
  }

  afterEach(() => {
    delete process.env.BUYLEDGER_FIXED_NOW;
  });

  it('generates monotonically increasing clocks under a fixed clock', () => {
    const svc = make('2024-01-01T00:00:00.000Z');
    const a = svc.generate();
    const b = svc.generate();
    expect(compareHlc(a, b)).toBe(-1);
    expect(b.c).toBe(a.c + 1);
    expect(a.w).toBe('server');
  });

  it('advances past a received remote clock so the next generate dominates it', () => {
    const svc = make('2024-01-01T00:00:00.000Z');
    const nowMs = new Date('2024-01-01T00:00:00.000Z').getTime();
    const remote: Hlc = { p: nowMs + 1000, c: 9, w: 'device-a' };
    svc.receive(remote);
    const next = svc.generate();
    expect(compareHlc(next, remote)).toBe(1);
  });

  it('rejects an out-of-tolerance future clock and accepts a near one', () => {
    const svc = make('2024-01-01T00:00:00.000Z');
    const nowMs = new Date('2024-01-01T00:00:00.000Z').getTime();
    expect(() =>
      svc.assertWithinTolerance({ p: nowMs + 6 * 60 * 1000, c: 0, w: 'x' }),
    ).toThrow();
    expect(() =>
      svc.assertWithinTolerance({ p: nowMs + 60 * 1000, c: 0, w: 'x' }),
    ).not.toThrow();
  });
});
