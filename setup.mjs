import { configureMacOS } from './scripts/zentao/macos.mjs';

configureMacOS().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
