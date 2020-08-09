import {exists, writeJson} from "https://deno.land/std@0.64.0/fs/mod.ts";
import {exec} from 'https://cdn.depjs.com/exec/mod.ts'

let token: string = '';
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
}

let list: githubRepoTags = {
    "nodes": [
        {
            "tagName": "v0.3"
        }
    ],
    "tag_name": "0",
    "totalCount": 0
};

if (import.meta.main) {

    let TK = /--token/g;
    let RB = /--rebuild/g;

    let getToke = Deno.args.filter(e => e.match(TK))
    let getRebuild = Deno.args.filter(e => e.match(RB))

    if (getToke.length > 1) {
        console.error("Provide a single flag for token")
        throw "exit";
    } else if (getToke.length === 1) {
        token = getToke[0] ?. replace("--token", "").replace("=", "")
    } else {
        console.error("Provide a token")
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
      }
      totalCount
    }
    }
}
`

const callGithub = async (token : string) => {
    function handleErrors(res: any) {
        if (! res.ok) {
            console.error("Got error from Github API")
            throw res.status;
        }
        return res;
    }
    await fetch('https://api.github.com/graphql', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(
            {query: `${query}`}
        )
    }).then(handleErrors).then(res => res.json()).then(res => list = res.data.repository.releases)
}

const update_latest_release = async (token : string) => {
    try {
        var dt = new Date();

        console.log(`${
            dt.toJSON()
        } Getting latest release information from Github.`)

        await callGithub(token)

        let data = list.nodes.sort((a, b) => b.tagName.localeCompare(a.tagName));

        let Be = /beta/g;
        let RC = /-rc/g;
        let CalVer = /v20./g;

        let latestBeta = data.filter(e => e.tagName.match(Be))
        let latestRC = data.filter(e => e.tagName.match(RC))
        let latestCalVer = data.filter(e => (e.tagName.match(CalVer) && !e.tagName.match(RC)) && !e.tagName.match(Be))
        let tag_name = latestCalVer[0].tagName;

        writeJson("./latest-release.txt", {latestBeta, latestRC, latestCalVer, tag_name});
    } catch (error) {
        throw error;
    }
}

const sleep = (ms : any) => new Promise(resolve => setTimeout(resolve, ms));

const execSYS = async ({Entrypoint, command, path} : execSYSOptions) => {
    try {
        return await exec({
            cmd: [
                `${Entrypoint}`, '-c', `${command}`
            ],
            cwd: `${
                path ? path : "./"
            }`
        })
    } catch (error) {
        console.log(error)
    }
}

const rebuildIt = async () => {

    await execSYS({Entrypoint: "sh", command: "apt-get update -y && apt-get upgrade -y", path: "./"})
    await execSYS({Entrypoint: "sh", command: "apt-get install -y curl bash git", path: "./"})
    await execSYS({Entrypoint: "sh", command: "deno upgrade --version 1.2.2"})

    await execSYS({Entrypoint: "sh", command: "[ -d Install-Dgraph_build ] || mkdir ./Install-Dgraph_build"})
    await execSYS({Entrypoint: "sh", command: "git clone https://github.com/dgraph-io/Install-Dgraph.git", path: "./Install-Dgraph_build"})
    await execSYS({Entrypoint: "sh", command: "rm -rf ./Install-Dgraph"})
    await execSYS({Entrypoint: "sh", command: "mv ./Install-Dgraph_build/Install-Dgraph ./ "})
    await execSYS({Entrypoint: "sh", command: "rm -rf ./Install-Dgraph_build"})

    console.log(await exec('deno -V'))
    console.log(await exec(['which', 'deno']))
    console.log(await exec(['which', 'git']))

}

if (rebuild) {
    console.log(await exec('pwd'))
    console.log('Starting rebuild')
    rebuildIt();
}

while (true) {
    update_latest_release(token);
    await sleep(120000);
}
