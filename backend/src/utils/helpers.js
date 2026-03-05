import { v4 as uuidv4 } from 'uuid';
import dayjs from 'dayjs';

/** Generate a UUID v4 */
export const genId = () => uuidv4();

/** Current UTC timestamp in ISO format */
export const now = () => dayjs().toISOString();

/**
 * Standard paginated response envelope
 */
export function paginate(data, { page = 1, limit = 20, total = 0 }) {
  return {
    success: true,
    data,
    meta: {
      page: Number(page),
      limit: Number(limit),
      total: Number(total),
      totalPages: Math.ceil(total / limit),
    },
  };
}

/**
 * Standard single-resource response envelope
 */
export function ok(data) {
  return { success: true, data };
}

/**
 * Format money integer (centimes) to display string
 */
export function formatMoney(centimes, currency = 'DZD') {
  const amount = (centimes / 100).toFixed(2);
  return `${amount} ${currency}`;
}

/**
 * Parse query string pagination params
 */
export function parsePagination(query) {
  const page = Math.max(1, parseInt(query.page) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit) || 20));
  const offset = (page - 1) * limit;
  return { page, limit, offset };
}

/**
 * Apply tenant_id filter for multi-tenant queries
 */
export function tenantScope(queryBuilder, tenantId) {
  return queryBuilder.where('tenant_id', tenantId).whereNull('deleted_at');
}
