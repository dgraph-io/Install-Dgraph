import {exists, writeJson} from "https://deno.land/std@0.63.0/fs/mod.ts";

let token: string = '';

interface githubRepoTags {
    nodes: Node[];
    totalCount: number;
    tag_name: string;
}

interface Node {
    tagName: string;
}

if (import.meta.main) {
    let TK = /--token/g;
    let getToke = Deno.args.filter(e => e.match(TK))
    if (getToke.length === 1) {
        token = getToke[0] ?. replace("--token", "").replace("=", "")
    }
    if (getToke.length === 0) {
        console.error("Provide a token")
        throw "exit";
    }
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

        writeJson("./latest-release.txt", {latestBeta, latestRC, latestCalVer, tag_name });
    } catch (error) {
        throw error;
    }
}

const sleep = (ms : any) => {
    return new Promise(resolve => setTimeout(resolve, ms));
}

while (true) {
    update_latest_release(token);
    await sleep(120000);
}
