import { exists, writeJson } from "https://deno.land/std@0.64.0/fs/mod.ts";
import { exec } from "https://deno.land/x/exec/mod.ts";

let token: string = "";
let rebuild: boolean = false;

interface execSYSOptions {
  Entrypoint?: string;
  command?: string;
  path?: string;
}

interface githubRepoTags {
  nodes: Node[];
  totalCount: number;
  tag_name: string;
}

interface Node {
  tagName: string;
  isDraft: boolean;
}

let list: githubRepoTags = {
  "nodes": [
    {
      "tagName": "v0.3",
      "isDraft": false,
    },
  ],
  "tag_name": "0",
  "totalCount": 0,
};

if (import.meta.main) {
  let TK = /--token/g;
  let RB = /--rebuild/g;

  let getToke = Deno.args.filter((e) => e.match(TK));
  let getRebuild = Deno.args.filter((e) => e.match(RB));

  if (getToke.length > 1) {
    console.error("Provide a single flag for token");
    throw "exit";
  } else if (getToke.length === 1) {
    token = getToke[0]?.replace("--token", "").replace("=", "");
  } else {
    console.error("Provide a token");
    throw "exit";
  }
  if (getRebuild.length === 1) {
    rebuild = true;
  }
}

let query = `query {
    repository(owner:"dgraph-io", name:"dgraph") {
     releases (first:100, orderBy: { field: CREATED_AT, direction: DESC }){
      nodes{
        tagName
        isDraft
      }
      totalCount
    }
    }
}`;

const callGithub = async (token: string) => {
  function handleErrors(res: any) {
    if (!res.ok) {
      console.error("Got error from Github API");
      throw res.status;
    }
    return res;
  }
  await fetch("https://api.github.com/graphql", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`,
    },
    body: JSON.stringify(
      { query: `${query}` },
    ),
  }).then(handleErrors).then((res) => res.json()).then((res) =>
    list = {
      nodes: res.data.repository.releases.nodes.filter((e: any) =>
        e.isDraft != true
      ),
      totalCount: res.data.repository.releases.totalCount,
      tag_name: "",
    }
  );
};

const update_latest_release = async (token: string) => {
  try {
    var dt = new Date();

    console.log(
      `${dt.toJSON()} Getting latest release information from Github.`,
    );

    await callGithub(token);

    let data = list.nodes.sort((a, b) => b.tagName.localeCompare(a.tagName));

    let Be = /beta/g;
    let RC = /-rc/g;
    let CalVer = /v(?<![0-9])[0-9]{2}(?![0-9])./g;

    let latestBeta = data.filter((e) => e.tagName.match(Be));
    let latestRC = data.filter((e) => e.tagName.match(RC));
    let calVer = data.filter((e) =>
      (e.tagName.match(CalVer) && !e.tagName.match(RC)) && !e.tagName.match(Be)
    );
    let releases = calVer.map((e) => {
      const splits = e.tagName.split(".");
      splits.pop();
      let JOK = splits.join(".");
      return JOK;
    });
    JSON.parse;

    const uniqueSet = new Set(releases);
    const majorReleases = [...uniqueSet];
    let tag_name = calVer[0].tagName;

    let latestCalVer: any = calVer.map((e: any) => {
      const setMax = (a: any) =>
        calVer.filter((e: any) => e.tagName.match(a)).reduce((
          prev: any,
          current: any,
        ) => prev.tagName > current.tagName ? prev : current);

      let getLatestForMajor = majorReleases.map(function (item: any) {
        if (!!e.tagName.match(item)) {
          return setMax(item);
        }
      }).filter((e) => e);

      return {
        tagName: e.tagName,
        isDraft: e.isDraft,
        latest: getLatestForMajor[0]?.tagName,
      };
    });

    writeJson(
      "./latest-release.txt",
      { latestBeta, latestRC, latestCalVer, tag_name, majorReleases },
    );
  } catch (error) {
    throw error;
  }
};

const sleep = (ms: any) => new Promise((resolve) => setTimeout(resolve, ms));

const execSYS = async ({ Entrypoint, command, path }: execSYSOptions) => {
  try {
    return await exec(
      `${command}`
    );
  } catch (error) {
    console.log(error);
  }
};

const rebuildIt = async () => {
  await execSYS(
    {
      Entrypoint: "sh",
      command: "apt-get update -y && apt-get upgrade -y",
      path: "./",
    },
  );
  await execSYS(
    {
      Entrypoint: "sh",
      command: "apt-get install -y curl bash git",
      path: "./",
    },
  );
  await execSYS({ Entrypoint: "sh", command: "deno upgrade --version 1.2.2" });

  await execSYS(
    {
      Entrypoint: "sh",
      command: "[ -d Install-Dgraph_build ] || mkdir ./Install-Dgraph_build",
    },
  );
  await execSYS(
    {
      Entrypoint: "sh",
      command: "git clone https://github.com/dgraph-io/Install-Dgraph.git",
      path: "./Install-Dgraph_build",
    },
  );
  await execSYS({ Entrypoint: "sh", command: "rm -rf ./Install-Dgraph" });
  await execSYS(
    {
      Entrypoint: "sh",
      command: "mv ./Install-Dgraph_build/Install-Dgraph ./ ",
    },
  );
  await execSYS({ Entrypoint: "sh", command: "rm -rf ./Install-Dgraph_build" });

  console.log(await exec("deno -V"));
  console.log(await exec("which deno"));
  console.log(await exec("which git"));
};

if (rebuild) {
  console.log(await exec("pwd"));
  console.log("Starting rebuild");
  rebuildIt();
}

while (true) {
  update_latest_release(token);
  await sleep(120000);
}
