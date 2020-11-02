import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

void main() => runApp(WeatherApp());

class WeatherApp extends StatefulWidget {
  @override
  WeatherAppState createState() => WeatherAppState();
}

class WeatherAppState extends State<WeatherApp> {
  int temperature ;
  String location = 'San Fransisco';
  int woeid = 2487956;
  String weather = 'clear';
  String abbreviation = '';
  String errorMessage = '';

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  Position currentPosition;
  String   currentAddress;

  void initState() {
    super.initState();
    fetchLocation();
  }

  void fetchSearch(String input) async {
    try {
      var searchResult = await http.get(searchApiUrl + input);
      var result = json.decode(searchResult.body)[0];
      setState(() {
        location = result["title"];
        woeid = result["woeid"];
        errorMessage = '';
      });
    }catch(error){
      errorMessage = "Sorry, we don't have the data for that location, please try another name ";
    }
  }

  void fetchLocation() async {
    var locationResult = await http.get(locationApiUrl + woeid.toString());
    var result = json.decode(locationResult.body);
    var consolidatedWeather = result["consolidated_weather"];
    var data = consolidatedWeather[0];

    setState(() {
      temperature = data["the_temp"].round();
      weather = data["weather_state_name"].replaceAll(' ', '').toLowerCase();
      abbreviation = data["weather_state_abbr"];
    });
  }

  void onTextFieldSubmitted(String input) async{
  await fetchSearch(input);
  await fetchLocation();
  }

  getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        currentPosition= position;
      });

      getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          currentPosition.latitude, currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        currentAddress =
        "${place.locality}, ${place.postalCode}, ${place.country}";
      });
      onTextFieldSubmitted(place.locality);
      print(place.locality);
    } catch (e) {
      print(e);
    }
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/$weather.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: temperature == null ? Center(child: CircularProgressIndicator(),)
            : Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: (){
                    getCurrentLocation();
                  },
                  child: Icon(Icons.location_city, size: 36.0,),
                ),
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0.0,
          ),
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Center(
                    child: Image.network(
                      'https://www.metaweather.com/static/img/weather/png/' + abbreviation + '.png',
                      width: 80.0,
                    ),
                  ),
                  Center(
                    child: Text(
                      temperature.toString() + '°C',
                      style: TextStyle(
                          fontSize: 50.0,
                          color: Colors.white,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                  Center(
                    child: Text(
                      location,
                      style: TextStyle(
                          fontSize: 40.0,
                          color: Colors.white,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  Container(
                    width: 300,
                    child: TextField(
                      onSubmitted: (String input) {
                        onTextFieldSubmitted(input);
                      },
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontStyle: FontStyle.italic,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for locations...',
                        hintStyle: TextStyle(color: Colors.white, fontSize: 20),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red, fontSize: 20.0, fontStyle: FontStyle.italic,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
