import { renderHome } from './ui';

export interface RuntimeEnv {
  CARTOGRAPHER: {
    getByName(name: string): {
      fetch(request: Request): Promise<Response> | Response;
    };
  };
}

export const routeRequest = async (request: Request, env: RuntimeEnv): Promise<Response> => {
  const url = new URL(request.url);

  if (request.method === 'GET' && url.pathname === '/') {
    return new Response(renderHome(), { headers: { 'content-type': 'text/html; charset=utf-8' } });
  }

  if (request.method === 'GET' && url.pathname === '/health') {
    return Response.json({ ok: true, service: 'jido-cartographer-worker', backend: '/api/health' });
  }

  if (url.pathname === '/api/health') {
    const backendUrl = new URL(request.url);
    backendUrl.pathname = '/health';
    return env.CARTOGRAPHER.getByName('shared').fetch(new Request(backendUrl, request));
  }

  if (url.pathname === '/api/index' || url.pathname.startsWith('/api/results/')) {
    return env.CARTOGRAPHER.getByName('shared').fetch(request);
  }

  return Response.json({ error: 'not found' }, { status: 404 });
};
