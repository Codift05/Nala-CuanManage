import { randomUUID } from 'node:crypto';
import { NextFunction, Request, Response } from 'express';
import { logInfo } from '../utils/logger';

const errorCode = (status: number): string => ({
  400: 'VALIDATION_ERROR',
  401: 'AUTHENTICATION_REQUIRED',
  403: 'FORBIDDEN',
  404: 'NOT_FOUND',
  409: 'CONFLICT',
  413: 'PAYLOAD_TOO_LARGE',
  422: 'UNPROCESSABLE_ENTITY',
  429: 'RATE_LIMITED',
}[status] ?? 'INTERNAL_ERROR');

export const normalizeErrorBody = (
  status: number,
  body: unknown,
  requestId: string,
) => {
  const source = body && typeof body === 'object'
    ? body as Record<string, unknown>
    : {};
  const message = typeof source.message === 'string'
    ? source.message
    : typeof source.error === 'string'
      ? source.error
      : status >= 500 ? 'Internal server error' : 'Request failed';

  return {
    ...source,
    message,
    error: { code: errorCode(status), message, requestId },
  };
};

export const requestContext = (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  const requestId = randomUUID();
  const startedAt = Date.now();
  const json = res.json.bind(res);

  res.locals.requestId = requestId;
  res.set('X-Request-ID', requestId);
  res.json = ((body: unknown) => json(
    res.statusCode >= 400
      ? normalizeErrorBody(res.statusCode, body, requestId)
      : body,
  )) as Response['json'];

  res.on('finish', () => logInfo('http.request', {
    requestId,
    method: req.method,
    path: req.path,
    status: res.statusCode,
    durationMs: Date.now() - startedAt,
  }));
  next();
};
