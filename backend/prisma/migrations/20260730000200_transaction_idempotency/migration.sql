ALTER TABLE "Transaction"
  ADD COLUMN "idempotencyKey" VARCHAR(128);

CREATE UNIQUE INDEX "Transaction_userId_idempotencyKey_key"
  ON "Transaction"("userId", "idempotencyKey");
