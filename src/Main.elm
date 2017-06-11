module Main exposing (..)

import Markdown
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode


-- APP


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


init : ( Model, Cmd Msg )
init =
    let
        model =
            initialModel
    in
        model ! [ getAllArticles, getDetailedForecasts, getTextualForecasts ]



-- MODEL


type alias Model =
    { articles : ArticleData
    , detailedForecasts : List DetailedForecast
    , textualForecasts : List TextualForecast
    }



-- { departures : List Departure
-- , stops : List StopID
-- , selectedStop : StopID
-- , articles : List Article
-- , loadError : String
-- }


type alias ArticleData =
    { articleList : List Article
    , error : Maybe String
    }


type alias Article =
    { url : String
    , title : String
    , ingress : String
    , body : String
    , slug : String
    , publish : Bool
    , created : String
    , modified : String
    }


type alias DetailedForecast =
    { from : String
    , to : String
    , icon : String
    , temperature : String
    , pressure : String
    , precipitation : String
    , windSpeed : WindSpeed
    , windDirection : WindDirection
    }


type alias WindDirection =
    { direction : String
    , degrees : String
    }


type alias WindSpeed =
    { beaufort : String
    , mps : String
    }


type alias TextualForecast =
    { from : String
    , to : String
    , kind : String
    , forecast : String
    }



-- type alias StopID =
--     Int
-- type alias Departure =
--     { recordedAt : String
--     , meta : DepartureDetail
--     }
-- type alias DepartureDetail =
--     { destination : String
--     , line : String
--     , time : DepartureTime
--     }
-- type alias DepartureTime =
--     { aimedArrival : String
--     , expectedArrival : String
--     , aimedDeparture : String
--     , expectedDeparture : String
--     }


initialArticleData : ArticleData
initialArticleData =
    { articleList = []
    , error = Nothing
    }


initialModel : Model
initialModel =
    { articles = initialArticleData
    , detailedForecasts = []
    , textualForecasts = []
    }



-- { departures = []
-- , stops = [ 3012120, 3012122, 3012121, 3010465, 3012123 ]
-- , selectedStop = 3012120
-- , articles = []
-- , loadError = ""
-- }
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UPDATE


type Msg
    = NoOp
    | GetArticles (Result Http.Error (List Article))
    | GetDetailedForecasts (Result Http.Error (List DetailedForecast))
    | GetTextualForecasts (Result Http.Error (List TextualForecast))



-- | LoadDepartures (Result Http.Error (List Departure))
-- | SetSelectedStop String


setArticleList : List Article -> Model -> Model
setArticleList articles model =
    let
        articleData =
            model.articles

        newArticleData =
            { articleData | articleList = articles }
    in
        { model | articles = newArticleData }


setArticleLoadError : String -> Model -> Model
setArticleLoadError err model =
    let
        articleData =
            model.articles

        newArticleData =
            { articleData | error = Just err }
    in
        { model | articles = newArticleData }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GetArticles (Result.Ok articles) ->
            ( model
                |> setArticleList articles
            , Cmd.none
            )

        GetArticles (Result.Err err) ->
            ( model
                |> setArticleLoadError (toString err)
                |> setArticleList []
            , Cmd.none
            )

        GetDetailedForecasts (Result.Ok forecasts) ->
            -- Should probably also add a check for empty list here?
            let
                newForecasts =
                    -- Take the first forecast after sorting by to-timestamp
                    List.sortBy (\f -> f.to) forecasts |> List.take 1
            in
                ( { model | detailedForecasts = newForecasts }, Cmd.none )

        GetDetailedForecasts (Result.Err _) ->
            ( { model | detailedForecasts = [] }, Cmd.none )

        GetTextualForecasts (Result.Ok forecasts) ->
            ( { model | textualForecasts = forecasts }, Cmd.none )

        GetTextualForecasts (Result.Err _) ->
            ( { model | textualForecasts = [] }, Cmd.none )



-- LoadDepartures (Result.Ok deps) ->
--     ( { model | departures = deps }, Cmd.none )
-- LoadDepartures (Result.Err err) ->
--     ( { model | departures = [], loadError = toString err }, Cmd.none )
-- SetSelectedStop stopId ->
--     let
--         stopIdIntValue =
--             Result.withDefault 3012120 (String.toInt stopId)
--     in
--         ( { model | selectedStop = stopIdIntValue, departures = [] }, getStopDepartures stopIdIntValue )


forecastLocation : String
forecastLocation =
    "?lat=59.943&lon=10.775"



-- Storo, Oslo, Norway


getTextualForecasts : Cmd Msg
getTextualForecasts =
    let
        request =
            Http.get ("/api/weather/location/text/" ++ forecastLocation) decodeTextualForecasts
    in
        Http.send GetTextualForecasts request


decodeTextualForecasts : Decode.Decoder (List TextualForecast)
decodeTextualForecasts =
    let
        forecastDecoder =
            Decode.list decodeTextualForecast
    in
        Decode.at [ "forecasts" ] forecastDecoder


decodeTextualForecast : Decode.Decoder TextualForecast
decodeTextualForecast =
    Decode.map4 TextualForecast
        (Decode.field "from" Decode.string)
        (Decode.field "to" Decode.string)
        (Decode.field "type" Decode.string)
        (Decode.field "forecast" Decode.string)


getDetailedForecasts : Cmd Msg
getDetailedForecasts =
    let
        request =
            Http.get ("/api/weather/location/" ++ forecastLocation) decodeDetailedForecasts
    in
        Http.send GetDetailedForecasts request


decodeDetailedForecasts : Decode.Decoder (List DetailedForecast)
decodeDetailedForecasts =
    let
        forecastDecoder =
            Decode.list decodeDetailedForecast
    in
        Decode.at [ "forecasts" ] forecastDecoder


decodeDetailedForecast : Decode.Decoder DetailedForecast
decodeDetailedForecast =
    Decode.map8 DetailedForecast
        (Decode.field "from" Decode.string)
        (Decode.field "to" Decode.string)
        (Decode.field "icon" decodeIcon)
        (Decode.field "temperature" decodeTemperature)
        (Decode.field "pressure" decodePressure)
        (Decode.field "precipitation" decodePrecipitation)
        (Decode.field "windSpeed" decodeWindSpeed)
        (Decode.field "windDirection" decodeWindDirection)


decodeIcon : Decode.Decoder String
decodeIcon =
    Decode.field "number" Decode.string


decodeTemperature : Decode.Decoder String
decodeTemperature =
    Decode.field "value" Decode.string


decodePressure : Decode.Decoder String
decodePressure =
    Decode.field "value" Decode.string


decodePrecipitation : Decode.Decoder String
decodePrecipitation =
    Decode.field "value" Decode.string


decodeWindSpeed : Decode.Decoder WindSpeed
decodeWindSpeed =
    Decode.map2 WindSpeed
        (Decode.field "name" Decode.string)
        (Decode.field "mps" Decode.string)


decodeWindDirection : Decode.Decoder WindDirection
decodeWindDirection =
    Decode.map2 WindDirection
        (Decode.field "name" Decode.string)
        (Decode.field "deg" Decode.string)


getAllArticles : Cmd Msg
getAllArticles =
    let
        request =
            Http.get "/api/articles/" decodeArticleList
    in
        Http.send GetArticles request


decodeArticleList : Decode.Decoder (List Article)
decodeArticleList =
    Decode.list decodeArticle


decodeArticle : Decode.Decoder Article
decodeArticle =
    Decode.map8 Article
        (Decode.field "url" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "ingress" Decode.string)
        (Decode.field "body" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.field "publish" Decode.bool)
        (Decode.field "created" Decode.string)
        (Decode.field "modified" Decode.string)



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ renderHeader
        , div [ id "about-me-widget", class "container" ] [ renderAboutMe ]
        , div [ id "forecast-widget", class "container" ] [ renderForecastWidget model ]
        , div [ id "main-content", class "container" ] [ renderArticles model ]
        ]


renderForecastWidget : Model -> Html Msg
renderForecastWidget model =
    div [ class "card" ]
        [ div [ class "card-content" ]
            [ case model.detailedForecasts of
                [] ->
                    div [ id "forecast-loading" ] [ h1 [] [ text "Please hold, while Knerten is loading the weather info at his current location" ] ]

                forecasts ->
                    renderForecast model
            ]
        ]


renderForecast : Model -> Html Msg
renderForecast model =
    let
        detailedForecast =
            let
                data =
                    -- List.sortBy (\f -> f.from) model.textualForecasts |> List.head
                    List.head model.detailedForecasts
            in
                renderDetailedForecast data

        textualForecast =
            let
                data =
                    List.sortBy (\f -> f.from) model.textualForecasts |> List.head
            in
                renderTextualForecast data
    in
        div [ id "forecast-content" ]
            [ div [ id "forecast-city" ] [ h1 [] [ text "Oslo" ] ]
            , detailedForecast
            , textualForecast
            ]


renderDetailedForecast : Maybe DetailedForecast -> Html Msg
renderDetailedForecast data =
    case data of
        Just h ->
            div [ id "forecast-detailed" ]
                [ div [ id "forecast-main-data" ]
                    [ div [ id "forecast-icon" ] [ img [ src ("/assets/weather/" ++ h.icon ++ ".svg") ] [] ]
                    , div [ id "forecast-degrees" ] [ span [] [ text (h.temperature ++ "°C") ] ]
                    ]
                , div [ id "forecast-details" ]
                    [ ul []
                        [ li [] [ span [] [ i [ class "fa fa-flag" ] [], text (h.windSpeed.mps ++ " m/s " ++ h.windDirection.direction) ] ]
                        , li [] [ span [] [ i [ class "fa fa-tint" ] [], text (h.precipitation ++ "mm") ] ]
                        , li [] [ span [] [ i [ class "fa fa-thermometer-full" ] [], text (h.pressure ++ " hPa") ] ]
                        ]
                    ]
                ]

        Nothing ->
            div [] [ p [] [ text "Unfortunately, Knerten could not find any forecast details..." ] ]


renderTextualForecast : Maybe TextualForecast -> Html Msg
renderTextualForecast data =
    div [ id "forecast-textual" ]
        [ case data of
            Just d ->
                p [] [ text d.forecast ]

            Nothing ->
                p [] [ text "Unfortunately, Knerten could not find any textual forecast..." ]
        ]


renderArticles : Model -> Html Msg
renderArticles model =
    section [ id "article-container" ]
        [ case model.articles.error of
            Just _ ->
                div [ id "article-loading", class "card" ] [ div [ class "card-content" ] [ h1 [] [ text "Unfortunately, Knerten were not able to collect his latest articles" ] ] ]

            Nothing ->
                case model.articles.articleList of
                    [] ->
                        div [ id "article-loading", class "card" ] [ div [ class "card-content" ] [ h1 [] [ text "Please hold, while Knerten is collecting his latest articles" ] ] ]

                    _ ->
                        div []
                            (model.articles.articleList
                                |> List.filter (\a -> a.publish == True)
                                |> List.map (\a -> renderArticle a)
                            )
        ]


renderArticle : Article -> Html Msg
renderArticle rawArticle =
    article [ class "article card" ]
        [ div [ class "card-content" ]
            [ section [ class "article-title" ] [ h1 [] [ text rawArticle.title ] ]
            , section [ class "article-ingress" ] [ p [] [ text rawArticle.ingress ] ]
            , section [ class "article-body" ] [ Markdown.toHtml [] rawArticle.body ]
            ]
        ]


renderAboutMe : Html Msg
renderAboutMe =
    div [ class "card" ]
        [ div [ id "about-me-content", class "card-content" ]
            [ div [ id "about-me-summary" ]
                [ div [ id "about-me-title" ]
                    [ h1 [] [ text "Håkon Ø. Løvdal" ]
                    , h2 [] [ text " M.Sc., in Informatics" ]
                    ]
                , div [ id "about-me-text" ] [ aboutMeText ]
                ]
            , div [ id "about-me-cv-picture" ] [ img [ src "/assets/img/me.png" ] [] ]
            ]
        ]


renderHeader : Html Msg
renderHeader =
    header [ id "main-header" ]
        [ div [ class "container" ]
            [ div [ id "logo" ] [ span [] [ text "h" ] ]
            , a [ href "/" ] [ h1 [] [ text "hakloev.no" ] ]
            , nav []
                [ ul []
                    [ li [] [ a [ href "https://cv.hakloev.no" ] [ text "CV" ] ]
                    , li [] [ a [ href "https://github.com/hakloev/" ] [ i [ class "fa fa-github fa-lg" ] [] ] ]
                    , li [] [ a [ href "https://twitter.com/hakloevdal/" ] [ i [ class "fa fa-twitter fa-lg" ] [] ] ]
                    ]
                ]
            ]
        ]


aboutMeText : Html Msg
aboutMeText =
    p [] [ text "I'm a programmer with a passion for web development. This site is used to learn new web technologies, and therefore like a never ending story - with new versions deployed continuously. I've recently concluded my Master's degree at NTNU." ]



-- getStopDepartures : StopID -> Cmd Msg
-- getStopDepartures stopId =
--     let
--         request =
--             Http.get ("http://reisapi.ruter.no/StopVisit/GetDepartures/" ++ toString stopId) decodeDepartureList
--     in
--         Http.send LoadDepartures request
-- decodeDepartureList : Decode.Decoder (List Departure)
-- decodeDepartureList =
--     Decode.list decodeDeparture
-- decodeDeparture : Decode.Decoder Departure
-- decodeDeparture =
--     Decode.map2 Departure
--         (Decode.field "RecordedAtTime" Decode.string)
--         (Decode.field "MonitoredVehicleJourney" decodeDepartureDetail)
-- decodeDepartureDetail : Decode.Decoder DepartureDetail
-- decodeDepartureDetail =
--     Decode.map3 DepartureDetail
--         (Decode.field "DestinationName" Decode.string)
--         (Decode.field "PublishedLineName" Decode.string)
--         (Decode.field "MonitoredCall" decodeDepartureTime)
-- decodeDepartureTime : Decode.Decoder DepartureTime
-- decodeDepartureTime =
--     Decode.map4 DepartureTime
--         (Decode.field "AimedArrivalTime" Decode.string)
--         (Decode.field "ExpectedArrivalTime" Decode.string)
--         (Decode.field "AimedDepartureTime" Decode.string)
--         (Decode.field "ExpectedDepartureTime" Decode.string)
-- departureDetail : Departure -> Html Msg
-- departureDetail departure =
--     div []
--         [ h2 [] [ text <| departure.meta.line ++ " - " ++ departure.meta.destination ]
--         -- , p [] [ text <| formatedDateString departure.meta.time.expectedArrival ]
--         , p [] [ text <| formatedDateString departure.meta.time.expectedDeparture ]
--         ]
-- stopSelect : List StopID -> Html Msg
-- stopSelect stops =
--     div []
--         [ select [ onInput SetSelectedStop ]
--             (List.map (\stopId -> option [ value (toString stopId) ] [ text (toString stopId) ]) stops)
--         ]
-- formatedDateString : String -> String
-- formatedDateString dateString =
--     case Date.fromString dateString of
--         Ok date ->
--             toString (Date.hour date) ++ ":" ++ padMinuteString (Date.minute date)
--         Err err ->
--             "Error parsing date"
-- padMinuteString : Int -> String
-- padMinuteString min =
--     if min < 10 then
--         "0" ++ toString min
--     else
--         toString min
