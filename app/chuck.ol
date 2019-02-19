interface ChuckNorrisIface {
RequestResponse: search
}

outputPort Chuck {
Location: "socket://api.chucknorris.io:443/"
Protocol: https {
	.osc.search.method = "get";
	.osc.search.alias = "jokes/search?query=%{query}"
}
Interfaces: ChuckNorrisIface
}

main
{
	search@Chuck( { .query = "Computer" } )( response )
}
