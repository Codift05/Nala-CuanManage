CREATE TABLE "HabitScoreSnapshot" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "period" VARCHAR(7) NOT NULL,
    "methodology" VARCHAR(50) NOT NULL,
    "score" INTEGER NOT NULL,
    "factors" JSONB NOT NULL,
    "actions" JSONB NOT NULL,
    "calculatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "HabitScoreSnapshot_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "HabitScoreSnapshot_userId_period_methodology_key"
ON "HabitScoreSnapshot"("userId", "period", "methodology");

CREATE INDEX "HabitScoreSnapshot_userId_calculatedAt_idx"
ON "HabitScoreSnapshot"("userId", "calculatedAt");

ALTER TABLE "HabitScoreSnapshot"
ADD CONSTRAINT "HabitScoreSnapshot_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
