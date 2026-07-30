CREATE TABLE "RecurringExecution" (
  "id" TEXT NOT NULL,
  "recurringBillId" TEXT NOT NULL,
  "period" VARCHAR(7) NOT NULL,
  "transactionId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "RecurringExecution_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "RecurringExecution_recurringBillId_period_key"
  ON "RecurringExecution"("recurringBillId", "period");

CREATE UNIQUE INDEX "RecurringExecution_transactionId_key"
  ON "RecurringExecution"("transactionId");

ALTER TABLE "RecurringExecution"
  ADD CONSTRAINT "RecurringExecution_recurringBillId_fkey"
  FOREIGN KEY ("recurringBillId") REFERENCES "RecurringBill"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "RecurringExecution"
  ADD CONSTRAINT "RecurringExecution_transactionId_fkey"
  FOREIGN KEY ("transactionId") REFERENCES "Transaction"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;
