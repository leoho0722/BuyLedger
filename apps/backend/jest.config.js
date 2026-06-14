/**
 * 後端單元測試設定 (Nest 慣例：ts-jest 轉譯、testRegex 收 src 下的 *.spec.ts)。
 * 沿用根 tsconfig 的 decorator metadata，供 Nest DI 測試使用。
 */
module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  transform: {
    '^.+\\.(t|j)s$': 'ts-jest',
  },
  collectCoverageFrom: ['**/*.(t|j)s'],
  coverageDirectory: '../coverage',
  testEnvironment: 'node',
};
