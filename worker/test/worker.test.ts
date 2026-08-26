import { describe, expect, it } from 'vitest';
import { routeRequest } from '../src/app';
import { renderHome } from '../src/ui';

const env = (response = new Response('backend')) => ({
  CARTOGRAPHER: {
    getByName: () => ({ fetch: async () => response }),
  },
}) as never;

describe('worker routes', () => {
  it('renders the index UI', async () => {
    const response = await routeRequest(new Request('https://example.com/'), env());
    expect(response.status).toBe(200);
    const html = await response.text();
    expect(html).toContain('jido-cartographer');
    expect(html).toContain('One lightweight Jido agent per source file');
    expect(html).toContain('/api/index');
  });

  it('routes indexing and result requests to the container', async () => {
    const indexResponse = await routeRequest(new Request('https://example.com/api/index', { method: 'POST' }), env());
    const resultResponse = await routeRequest(new Request('https://example.com/api/results/abc'), env());
    expect(await indexResponse.text()).toBe('backend');
    expect(await resultResponse.text()).toBe('backend');
  });

  it('rewrites backend health and rejects unknown routes', async () => {
    const health = await routeRequest(new Request('https://example.com/health'), env());
    const payload = await health.json() as { service: string };
    expect(payload.service).toBe('jido-cartographer-worker');
    expect((await routeRequest(new Request('https://example.com/nope'), env())).status).toBe(404);
  });
});

describe('UI contract', () => {
  it('contains summary, language, dependency, timing, file, and error surfaces', () => {
    const html = renderHome();
    for (const sentinel of ['id="metrics"', 'id="languages"', 'id="edges"', 'id="files"', 'class="status"', 'analysis_ms', 'total_ms']) {
      expect(html).toContain(sentinel);
    }
  });
});
