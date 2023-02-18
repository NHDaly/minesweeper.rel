import { Client, readConfig } from '@relationalai/rai-sdk-javascript';
import { show } from './show';

async function run() {
    const profile = "flex";
    const database = "nhd-minesweeper";
    const engine = "nhd-m";

    const config = await readConfig(profile);
    const client = new Client(config);

    const queryString = `
        def output = display_cell
    `;

    const result = await client.query(
      database,
      engine,
      queryString,
      [],
      readonly,
    );

    show(result);
  }
