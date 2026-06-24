import { BadRequestException, Injectable } from '@nestjs/common';

import { NowService } from '../common/now.service';
import {
  Hlc,
  SERVER_WRITER_ID,
  compareHlc,
  decodeHlc,
  encodeHlc,
  generateHlc,
  isWithinSkewTolerance,
  receiveHlc,
} from './hlc';

// 後端的 HLC 權威端：以 NowService 為物理時間來源、writerId 固定 'server'，
// 維持單調遞增的 lastIssued (跨請求於進程記憶體內)，作為跨裝置合併的線性化點
@Injectable()
export class HlcService {
  private lastIssued: Hlc | null = null;

  constructor(private readonly now: NowService) {}

  /** 產生下一個伺服器時鐘 (本地事件) 並推進 lastIssued */
  generate(): Hlc {
    const next = generateHlc(this.lastIssued, this.now.now().getTime(), SERVER_WRITER_ID);
    this.lastIssued = next;
    return next;
  }

  /** 觀察到 client 帶來的遠端時鐘後推進 lastIssued (合併前必跑) */
  receive(remote: Hlc): void {
    this.lastIssued = receiveHlc(
      this.lastIssued,
      remote,
      this.now.now().getTime(),
      SERVER_WRITER_ID,
    );
  }

  /** 偏移守門：incoming 超過容忍界即 400 (刻意不靜默 clamp，以保重送冪等) */
  assertWithinTolerance(remote: Hlc): void {
    if (!isWithinSkewTolerance(remote.p, this.now.now().getTime())) {
      throw new BadRequestException('HLC physical time exceeds allowed skew tolerance');
    }
  }

  // 純函式的薄包裝：時鐘排序與線傳編解碼委派給 ./hlc，集中在 service 供 DI 注入
  compare(a: Hlc, b: Hlc): number {
    return compareHlc(a, b);
  }

  encode(h: Hlc): string {
    return encodeHlc(h);
  }

  decode(s: string): Hlc {
    return decodeHlc(s);
  }
}
