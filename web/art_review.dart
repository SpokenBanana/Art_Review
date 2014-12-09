import 'dart:html';
import 'dart:math';
import 'dart:convert';
import 'package:animation/animation.dart';

void main() {
  Quiz quiz = new Quiz();
  querySelector("#next").hidden = true;
  querySelector("#next").onClick.listen(quiz.nextSlideHandler);
  HttpRequest.getString("answers.json")
  .then(quiz.handleJSON);
}

class Quiz {
  List<Question> data;

  List<num> answered;
  var titleSub, artistSub, dateSub;
  num current;
  num tries;

  String buttonColor = '#2b4351';

  Quiz() {
    data = new List<Question>();
    answered = new List<num>();
    tries = 3;

    setHandlers(keyHandler);
  }
  void keyHandler(KeyboardEvent e) {
    if (e.keyCode == 13) {
      String Title = (querySelector("#title") as InputElement).value;
      String Date = (querySelector("#date") as InputElement).value;
      String Artist = (querySelector("#artist") as InputElement).value;

      // check the answers
      if (this.data[current].checkAnswers(Title, Date, Artist)) {

        // show that the user got it right
        updateStatus("green", "Corret!");
        querySelector("#next").hidden = false;

        // update progress
        answered.add(current);
        updateCounter();

        //finished quiz
        if (answered.length == data.length) {
          updateStatus("blue", "Thats all of the art! Continue to start over.");
        }

        setHandlers(nextSlideHandler);
      }
      else {
        tries--;
        shakeImage();

        if (tries == 0) {

          // show user he got it wrong
          querySelector("#next").hidden = false;
          addToWorkOn(current);
          updateStatus("darkred", "Out of tries. Here are the answers, learn them!");

          // update progress
          answered.add(current);
          updateCounter();


          if (answered.length == data.length) {
            updateStatus("blue", "Thats all of the art! Continue to start over.");
          }

          // show answers
          (querySelector("#title") as InputElement).value = data[current].title[0];
          (querySelector("#artist") as InputElement).value = data[current].artist[0];
          (querySelector("#date") as InputElement).value = data[current].date[0];

          setHandlers(nextSlideHandler);
        }
        else
         updateStatus("red", "Wrong");
      }
    }
  }

  // adds to list so user knows which art pieces he got wrong
  void addToWorkOn(num toWorkOn) {
    var element = document.createElement("li");
    element.innerHtml = "<b>"+data[toWorkOn].title[0] + "</b> " + data[toWorkOn].artist[0] + " <i>" + data[toWorkOn].date[0] +"</i>";
    querySelector("#work-on").append(element);
  }

  // has user move to next art piece
  void nextSlideHandler(Event e) {
    setHandlers(keyHandler);
    querySelector("#next").hidden = true;
    tries = 3;

    // get next question
    if (answered.length != data.length)
      current = getRandomQuestion();
    else {
      // finished all of them, start over
      answered.clear();
      querySelector('#work-on').innerHtml = '';
      (querySelector("#image") as ImageElement).src = '';
      current = getRandomQuestion();
    }

    querySelector("#title").style.backgroundColor = buttonColor;
    querySelector("#date").style.backgroundColor = buttonColor;
    querySelector("#artist").style.backgroundColor = buttonColor;

    // load next picture
    var animation = new ElementAnimation(querySelector("#image"))
    ..duration = 500
    ..properties = {
      'left': 1200
    };
    var backIn = new ElementAnimation(querySelector("#image"))
        ..duration = 500
        ..properties = {
          'left': 0
    };
    
    var queue = new AnimationQueue()
    ..add(animation)
    ..run();
    
    (querySelector("#image") as ImageElement).src = this.data[current].src;
    (querySelector("#image") as ImageElement).onLoad.listen((e) {
      loadNextPic();
      queue
      ..add(backIn)
      ..run();
    });

    updateStatus("black", "Loading...");
    updateCounter();


    // clear the input values
    (querySelector("#title") as InputElement).value = '';
    (querySelector("#date") as InputElement).value = '';
    (querySelector("#artist") as InputElement).value = '';
  }
  
  void shakeImage() {
    var image = querySelector("#image");
    print(image);
    var leftAnim1 = new ElementAnimation(image)
    ..duration = 250
    ..properties = {
      'left': 100,
    };
    
    var rightAnim = new ElementAnimation(image)
        ..duration = 100
        ..properties = {
          'left': -100,
    };
    
    var leftAnim2 = new ElementAnimation(image)
        ..duration = 100
        ..properties = {
          'left': 100,
    };
    
    var finalAnim = new ElementAnimation(image)
        ..duration = 250
        ..properties = {
          'left': 0,
    };
    
    var queue = new AnimationQueue()
        ..addAll([leftAnim1, rightAnim, leftAnim2, finalAnim])
        ..run();
  }

  void setHandlers([handler(KeyboardEvent e)]) {
    if (titleSub != null)
      titleSub.cancel();
    if (artistSub != null)
      artistSub.cancel();
    if (dateSub != null)
      dateSub.cancel();

    titleSub = querySelector("#title").onKeyDown.listen(handler);
    artistSub = querySelector("#artist").onKeyDown.listen(handler);
    dateSub = querySelector("#date").onKeyDown.listen(handler);
  }

  void loadNextPic() {
    updateCounter();
    updateStatus("white", "");
  }

  void updateCounter() {
    querySelector("#amount").text = answered.length.toString() + " out of " + data.length.toString() + " answered";
  }

  // gives back index of an art not yet answered
  num getRandomQuestion() {
    var rgen = new Random();
    num other;
    do {
      other = rgen.nextInt(this.data.length);
    } while(answered.contains(other));
    return other;
  }

  // takes the json of all the art data and turns it into questions
  void handleJSON(String stringJSON) {
    Map raw = JSON.decode(stringJSON);
    List<Map<String, List<String>>> allData = raw['art'];
    allData.forEach((item) {
      this.data.add(new Question(item['title'], item['date'], item['artist'], item['image']));
    });
    current = getRandomQuestion();
    (querySelector("#image") as ImageElement).src = this.data[current].src;
    loadNextPic();
  }

  void updateStatus(String color, String message) {
    querySelector("#status").style.color = color;
    querySelector("#status").innerHtml = message;
    String tryColor = 'green';
    switch (tries) {
      case 2:
        tryColor = 'orange';
        break;
      case 1:
        tryColor = 'red';
        break;
    }
    querySelector("#tries").style.color = tryColor;
    querySelector("#tries").innerHtml = "Tries: " + tries.toString();
  }

}

// to represent an art piece for user to identify
class Question {
  List<String> title;
  List<String> date;
  List<String> artist;
  String src;

  Question(List<String> _title, List<String> _date, List<String> _artist, String image) {
    title = _title;
    date = _date;
    artist = _artist;
    src = image;
  }

  bool checkAnswers(String _title, String _date, String _artist) {
    // don't want the user to get it wrong because of some trivial reason
    _artist = _artist.toLowerCase().trim();
    _date = _date.toLowerCase().trim();
    _title = _title.toLowerCase().trim();

    querySelector("#title").style.backgroundColor = (title.contains(_title)) ? 'green' : 'red';
    querySelector("#date").style.backgroundColor = (date.contains(_date)) ? 'green' : 'red';
    querySelector("#artist").style.backgroundColor = (artist.contains(_artist)) ? 'green' : 'red';

    return title.contains(_title) && date.contains(_date) &&
            artist.contains(_artist);
  }
}