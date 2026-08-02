import { Request, Response } from 'express';
import prisma from '../utils/prisma';
import { parseRupiah } from '../utils/money';
import { parseIdempotencyKey } from '../utils/idempotency';
import {
  createTransactionCursor,
  parseTransactionDate,
  parseTransactionCursor,
  parseTransactionLimit,
  parseTransactionType,
} from '../utils/transactionInput';
import { parseText } from '../utils/resourceInput';
import { logError } from '../utils/logger';

export const createTransaction = async (req: Request, res: Response) => {
  try {
    const { walletId, type, amount, categoryId, merchant, notes, date } = req.body;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    if (!walletId || !type || amount === undefined) {
      return res.status(400).json({ message: 'walletId, type, and amount are required' });
    }

    const transactionType = parseTransactionType(type);
    if (!transactionType) {
      return res.status(400).json({ message: 'type must be INCOME or EXPENSE' });
    }

    const transactionDate = parseTransactionDate(date);
    if (transactionDate === null) {
      return res.status(400).json({ message: 'date must be a valid ISO date' });
    }

    const idempotencyKey = parseIdempotencyKey(req.get('Idempotency-Key'));
    if (!idempotencyKey) {
      return res.status(400).json({ message: 'Valid Idempotency-Key header is required' });
    }

    const numericAmount = parseRupiah(amount);
    if (numericAmount === null) {
      return res.status(400).json({ message: 'amount must be a whole rupiah value' });
    }
    const parsedWalletId = parseText(walletId, 100);
    const parsedCategory = parseText(categoryId, 50, { optional: true });
    const parsedMerchant = parseText(merchant, 100, { optional: true });
    const parsedNotes = parseText(notes, 500, { optional: true });
    if (
      !parsedWalletId ||
      parsedCategory === null ||
      parsedMerchant === null ||
      parsedNotes === null
    ) {
      return res.status(400).json({ message: 'Transaction text fields are invalid' });
    }

    const existingTransaction = await prisma.transaction.findUnique({
      where: { userId_idempotencyKey: { userId, idempotencyKey } },
      include: { wallet: { select: { name: true, type: true } } }
    });
    if (existingTransaction) {
      const sameRequest =
        existingTransaction.walletId === parsedWalletId &&
        existingTransaction.type === transactionType &&
        existingTransaction.amount === numericAmount &&
        existingTransaction.categoryId === (parsedCategory ?? null) &&
        existingTransaction.merchant === (parsedMerchant ?? null) &&
        existingTransaction.notes === (parsedNotes ?? null) &&
        (transactionDate === undefined ||
          existingTransaction.date.getTime() === transactionDate.getTime());
      if (!sameRequest) {
        return res.status(409).json({
          message: 'Idempotency-Key sudah digunakan untuk transaksi berbeda'
        });
      }
      return res.status(200).json({
        message: 'Transaction already processed',
        transaction: existingTransaction,
        replayed: true
      });
    }

    const wallet = await prisma.wallet.findFirst({
      where: { id: parsedWalletId, userId }
    });
    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }

    const balanceChange = transactionType === 'INCOME' ? numericAmount : -numericAmount;

    let warning: string | undefined;
    if (transactionType === 'EXPENSE' && wallet.balance < numericAmount) {
      warning = 'Saldo dompet menjadi minus setelah transaksi ini.';
    }

    // Use a transaction to ensure both operations succeed or fail together
    const { transaction, updatedWallet } = await prisma.$transaction(async (tx) => {
      const transaction = await tx.transaction.create({
        data: {
          userId,
          walletId: parsedWalletId,
          type: transactionType,
          amount: numericAmount,
          categoryId: parsedCategory,
          merchant: parsedMerchant,
          notes: parsedNotes,
          idempotencyKey,
          date: transactionDate
        }
      });
      const updatedWallet = await tx.wallet.update({
        where: { id: parsedWalletId },
        data: {
          balance: {
            increment: balanceChange
          }
        }
      });
      await tx.auditLog.create({
        data: {
          actorUserId: userId,
          action: 'TRANSACTION_CREATED',
          resourceType: 'TRANSACTION',
          resourceId: transaction.id,
          requestId: res.locals.requestId,
          metadata: {
            walletId: parsedWalletId,
            type: transactionType,
            amount: numericAmount.toString(),
          },
        },
      });
      return { transaction, updatedWallet };
    });

    res.status(201).json({
      message: 'Transaction created successfully',
      transaction,
      wallet: updatedWallet,
      warning,
      replayed: false
    });
  } catch (error) {
    logError('transaction.create_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getTransactions = async (req: Request, res: Response) => {
  try {
    const userId = req.userId;
    const { walletId, type, categoryId, limit, cursor, from, to } = req.query;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const transactionType = type === undefined
      ? undefined
      : parseTransactionType(type);
    if (transactionType === null) {
      return res.status(400).json({ message: 'type must be INCOME or EXPENSE' });
    }

    const transactionLimit = parseTransactionLimit(limit);
    if (transactionLimit === null) {
      return res.status(400).json({ message: 'limit must be an integer from 1 to 100' });
    }
    const transactionCursor = parseTransactionCursor(cursor);
    if (transactionCursor === null) {
      return res.status(400).json({ message: 'cursor is invalid' });
    }
    const parsedWalletId = parseText(walletId, 100, { optional: true });
    const parsedCategory = parseText(categoryId, 50, { optional: true });
    if (parsedWalletId === null || parsedCategory === null) {
      return res.status(400).json({ message: 'walletId or categoryId is invalid' });
    }
    const dateFrom = parseTransactionDate(from);
    const dateTo = parseTransactionDate(to);
    if (dateFrom === null || dateTo === null ||
        (dateFrom && dateTo && dateFrom >= dateTo)) {
      return res.status(400).json({ message: 'from and to must be a valid ascending ISO date range' });
    }

    const whereClause: any = { userId };

    if (parsedWalletId) whereClause.walletId = parsedWalletId;
    if (transactionType) whereClause.type = transactionType;
    if (parsedCategory) whereClause.categoryId = parsedCategory;
    if (dateFrom || dateTo) {
      whereClause.date = {
        ...(dateFrom && { gte: dateFrom }),
        ...(dateTo && { lt: dateTo }),
      };
    }
    if (transactionCursor) {
      whereClause.AND = [{
        OR: [
          { date: { lt: transactionCursor.date } },
          { date: transactionCursor.date, id: { lt: transactionCursor.id } },
        ],
      }];
    }

    const pageSize = transactionLimit ?? 20;

    const transactions = await prisma.transaction.findMany({
      where: whereClause,
      orderBy: [{ date: 'desc' }, { id: 'desc' }],
      take: pageSize + 1,
      include: {
        wallet: {
          select: { name: true, type: true }
        }
      }
    });

    const hasMore = transactions.length > pageSize;
    const data = hasMore ? transactions.slice(0, pageSize) : transactions;
    const last = data.at(-1);
    res.json({
      data,
      pagination: {
        hasMore,
        nextCursor: hasMore && last
          ? createTransactionCursor({ date: last.date, id: last.id })
          : null,
      },
    });
  } catch (error) {
    logError('transaction.list_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getTransactionById = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const transaction = await prisma.transaction.findFirst({
      where: { id, userId },
      include: {
        wallet: {
          select: { name: true, type: true }
        }
      }
    });

    if (!transaction) {
      return res.status(404).json({ message: 'Transaction not found' });
    }

    res.json(transaction);
  } catch (error) {
    logError('transaction.get_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const deleteTransaction = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const transaction = await prisma.transaction.findFirst({
      where: { id, userId }
    });

    if (!transaction) {
      return res.status(404).json({ message: 'Transaction not found' });
    }

    // Revert the balance change
    const balanceChange = transaction.type === 'INCOME' ? -transaction.amount : transaction.amount;

    await prisma.$transaction(async (tx) => {
      await tx.transaction.delete({
        where: { id }
      });
      await tx.wallet.update({
        where: { id: transaction.walletId },
        data: {
          balance: {
            increment: balanceChange
          }
        }
      });
      await tx.auditLog.create({
        data: {
          actorUserId: userId,
          action: 'TRANSACTION_DELETED',
          resourceType: 'TRANSACTION',
          resourceId: id,
          requestId: res.locals.requestId,
          metadata: {
            walletId: transaction.walletId,
            type: transaction.type,
            amount: transaction.amount.toString(),
          },
        },
      });
    });

    res.json({ message: 'Transaction deleted successfully' });
  } catch (error) {
    logError('transaction.delete_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateTransaction = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const userId = req.userId;
    const { walletId, type, amount, categoryId, merchant, notes, date } = req.body;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    if (!walletId || !type || amount === undefined) {
      return res.status(400).json({ message: 'walletId, type, and amount are required' });
    }

    const transactionType = parseTransactionType(type);
    if (!transactionType) {
      return res.status(400).json({ message: 'type must be INCOME or EXPENSE' });
    }

    const transactionDate = parseTransactionDate(date);
    if (transactionDate === null) {
      return res.status(400).json({ message: 'date must be a valid ISO date' });
    }

    const numericAmount = parseRupiah(amount);
    if (numericAmount === null) {
      return res.status(400).json({ message: 'amount must be a whole rupiah value' });
    }
    const parsedWalletId = parseText(walletId, 100);
    const parsedCategory = parseText(categoryId, 50, { optional: true });
    const parsedMerchant = parseText(merchant, 100, { optional: true });
    const parsedNotes = parseText(notes, 500, { optional: true });
    if (
      !parsedWalletId ||
      parsedCategory === null ||
      parsedMerchant === null ||
      parsedNotes === null
    ) {
      return res.status(400).json({ message: 'Transaction text fields are invalid' });
    }

    const oldTransaction = await prisma.transaction.findFirst({
      where: { id, userId }
    });

    if (!oldTransaction) {
      return res.status(404).json({ message: 'Transaction not found' });
    }

    const newWallet = await prisma.wallet.findFirst({ where: { id: parsedWalletId, userId } });
    if (!newWallet) return res.status(404).json({ message: 'New Wallet not found' });

    let warning: string | undefined;

    await prisma.$transaction(async (tx) => {
      // 1. Revert old transaction
      const revertAmount = oldTransaction.type === 'INCOME' ? -oldTransaction.amount : oldTransaction.amount;
      await tx.wallet.update({
        where: { id: oldTransaction.walletId },
        data: { balance: { increment: revertAmount } }
      });

      // 2. Apply new transaction
      const applyAmount = transactionType === 'INCOME' ? numericAmount : -numericAmount;

      const currentNewWallet = await tx.wallet.findUnique({ where: { id: parsedWalletId } });
      if (transactionType === 'EXPENSE' && currentNewWallet && (currentNewWallet.balance - numericAmount < 0)) {
        warning = 'Saldo dompet menjadi minus setelah transaksi ini.';
      }

      await tx.wallet.update({
        where: { id: parsedWalletId },
        data: { balance: { increment: applyAmount } }
      });

      // 3. Update transaction record
      await tx.transaction.update({
        where: { id },
        data: {
          walletId: parsedWalletId,
          type: transactionType,
          amount: numericAmount,
          categoryId: parsedCategory,
          merchant: parsedMerchant,
          notes: parsedNotes,
          date: transactionDate
        }
      });
      await tx.auditLog.create({
        data: {
          actorUserId: userId,
          action: 'TRANSACTION_UPDATED',
          resourceType: 'TRANSACTION',
          resourceId: id,
          requestId: res.locals.requestId,
          metadata: {
            previous: {
              walletId: oldTransaction.walletId,
              type: oldTransaction.type,
              amount: oldTransaction.amount.toString(),
            },
            current: {
              walletId: parsedWalletId,
              type: transactionType,
              amount: numericAmount.toString(),
            },
          },
        },
      });
    });

    const updatedTransaction = await prisma.transaction.findUnique({
      where: { id },
      include: { wallet: { select: { name: true, type: true } } }
    });

    res.json({ message: 'Transaction updated successfully', transaction: updatedTransaction, warning });
  } catch (error) {
    logError('transaction.update_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
