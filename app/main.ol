include "internal/leonardo/ports/LeonardoAdmin.iol"

outputPort Chuck {
Location: "socket://api.chucknorris.io:443/"
Protocol: https {
	.osc.search.method = "get";
	.osc.search.alias = "jokes/search?query=%{query}"
}
RequestResponse: search
}

embedded {
Jolie:
	"-C Standalone=false internal/leonardo/cmd/leonardo/main.ol" in LeonardoAdmin
}

include "string_utils.iol"

outputPort Telegraph {
	Location: "socket://api.telegra.ph:443/"
	Protocol: https {
		format = "json"
		osc.createAccount.alias =
			"createAccount?short_name=%{short_name}"
		osc.createPage.alias =
			"createPage?access_token=%{access_token}&title=%{title}&content=[\"%{content}\"]"
	}
	RequestResponse: createAccount, createPage
}

type CreatePageRequest:void { title:string content:string }

interface TelegraphPosterIface {
RequestResponse: createPage(CreatePageRequest)(string) throws TelegraphError(string)
}

service TelegraphPoster {
	Interfaces: TelegraphPosterIface
	main {
		createPage( postRequest )( postUrl ) {
			short_name = new
			replaceAll@StringUtils( short_name { regex = "-", replacement = "" } )( short_name )
			createAccount@Telegraph( { short_name = short_name } )( response )
			if ( !response.ok ) throw( TelegraphError, response.error )
			access_token = response.result.access_token
			createPage@Telegraph( {
				access_token = access_token,
				title = postRequest.title,
				content = postRequest.content
			} )( response )
			if ( !response.ok ) throw( TelegraphError, response.error )
			postUrl = response.result.url
		}
	}
}

main
{
	config@LeonardoAdmin( {
		wwwDir = "../web"
		redirection[0] << {
			name = "ChuckNorris"
			binding -> Chuck
		}
		redirection[1] << {
			name = "TelegraphPoster"
			binding.location = TelegraphPoster.location
		}
	} )()
	linkIn( Shutdown )
}
