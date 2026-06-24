import { Injectable, OnModuleInit } from '@nestjs/common';
import { App, cert, getApps, initializeApp } from 'firebase-admin/app';
import { Auth, getAuth } from 'firebase-admin/auth';
import { Firestore, getFirestore } from 'firebase-admin/firestore';
import { Storage, getStorage } from 'firebase-admin/storage';
import { resolveFirebaseCredentialSource } from './firebase.config';

// 具名 app，避免與其他 firebase-admin 初始化 (或測試重複初始化) 衝突
const APP_NAME = 'buyledger';

// firebase-admin 初始化點。對齊 spec「Missing Firebase credentials fail closed」：
// 初始化於 onModuleInit，缺憑證時 resolveFirebaseCredentialSource 拋錯，Nest bootstrap 隨之失敗，
// 受保護端點不會在未驗證狀態下對外服務。憑證可用 service account JSON 檔或三個分開的環境變數
@Injectable()
export class FirebaseService implements OnModuleInit {
  private app!: App;

  onModuleInit(): void {
    const source = resolveFirebaseCredentialSource(process.env);
    const credential =
      source.kind === 'file'
        ? cert(source.path)
        : cert({
            projectId: source.credentials.projectId,
            clientEmail: source.credentials.clientEmail,
            privateKey: source.credentials.privateKey,
          });
    const existing = getApps().find((a) => a.name === APP_NAME);
    this.app =
      existing ??
      initializeApp(
        {
          credential,
          // 供訂單照片上傳使用；未設定時 storage() 取用預設 bucket
          storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
        },
        APP_NAME,
      );
  }

  get auth(): Auth {
    return getAuth(this.app);
  }

  get firestore(): Firestore {
    return getFirestore(this.app);
  }

  get storage(): Storage {
    return getStorage(this.app);
  }
}
