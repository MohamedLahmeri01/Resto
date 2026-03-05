import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok, paginate, parsePagination } from '../../utils/helpers.js';

export default async function notificationRoutes(fastify) {
  const db = fastify.knex;

  // GET /notifications/log
  fastify.get('/log', { preHandler: [verifyJWT, requirePermission('notifications.view')] }, async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const { channel, status } = req.query;
    let query = db('notifications_log').where({ tenant_id: req.tenantId });
    if (channel) query = query.where('channel', channel);
    if (status) query = query.where('status', status);
    const total = await query.clone().count('id as count').first();
    return paginate(
      await query.orderBy('created_at', 'desc').limit(limit).offset(offset),
      { page, limit, total: total?.count || 0 },
    );
  });

  // POST /notifications/send — Direct send (email/sms)
  fastify.post('/send', { preHandler: [verifyJWT, requirePermission('notifications.send')] }, async (req) => {
    const { recipient, channel, subject, body, template } = req.body;
    const id = genId();
    await db('notifications_log').insert({
      id, tenant_id: req.tenantId,
      recipient, channel, template, subject, body,
      status: 'queued',
    });
    // In production, this would be pushed to BullMQ queue
    // For now, mark as sent
    await db('notifications_log').where({ id }).update({ status: 'sent', sent_at: new Date() });
    return ok({ id, status: 'sent' });
  });

  // POST /notifications/campaigns — Campaign creation
  fastify.post('/campaigns', { preHandler: [verifyJWT, requirePermission('crm.campaigns')] }, async (req) => {
    const { audience_filter, subject_fr, subject_ar, body_fr, body_ar, channel, schedule_at } = req.body;

    // Resolve audience
    let customersQuery = db('customers').where({ tenant_id: req.tenantId });
    if (audience_filter?.tier_id) customersQuery = customersQuery.where('loyalty_tier_id', audience_filter.tier_id);
    if (audience_filter?.min_visits) customersQuery = customersQuery.where('total_visits', '>=', audience_filter.min_visits);
    if (audience_filter?.birthday_month) customersQuery = customersQuery.whereRaw('MONTH(birthday) = ?', [audience_filter.birthday_month]);

    const customers = await customersQuery.select('id', 'email', 'phone', 'preferred_locale');
    const audienceCount = customers.length;

    // Queue notifications
    for (const customer of customers) {
      const locale = customer.preferred_locale || 'fr';
      const subject = locale === 'ar' ? subject_ar : subject_fr;
      const body = locale === 'ar' ? body_ar : body_fr;
      const recipient = channel === 'email' ? customer.email : customer.phone;
      if (!recipient) continue;

      await db('notifications_log').insert({
        id: genId(), tenant_id: req.tenantId,
        recipient, channel: channel || 'email',
        subject, body, status: 'queued',
      });
    }

    return ok({ audience_count: audienceCount, notifications_queued: audienceCount, scheduled_at: schedule_at || 'immediate' });
  });
}
