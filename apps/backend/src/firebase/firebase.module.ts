import { Global, Module } from '@nestjs/common';
import { FirebaseService } from './firebase.service';
import { FirestoreMirrorService } from './firestore-mirror.service';

// 全域提供 FirebaseService (auth / firestore / storage 進入點) 與 FirestoreMirrorService
// (後端唯一寫入方的鏡像器)，供 auth guard 與各領域 service 注入使用
@Global()
@Module({
  providers: [FirebaseService, FirestoreMirrorService],
  exports: [FirebaseService, FirestoreMirrorService],
})
export class FirebaseModule {}
