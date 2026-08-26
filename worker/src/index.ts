import { Container } from '@cloudflare/containers';
import { routeRequest, type RuntimeEnv } from './app';

interface Env extends RuntimeEnv {
  CARTOGRAPHER: DurableObjectNamespace<CartographerContainer> & RuntimeEnv['CARTOGRAPHER'];
}

export class CartographerContainer extends Container<Env> {
  defaultPort = 8080;
  sleepAfter = '10m';
}

export default { fetch: routeRequest } satisfies ExportedHandler<Env>;
