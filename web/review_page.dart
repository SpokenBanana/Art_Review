import 'dart:html';
import 'dart:convert';

void main() {
  new Review();
}

class Review {
  List<Map<String, List<String>>> data;

  Review() {
    HtmlElement content = querySelector('#images');
    HttpRequest.getString("answers.json")
    .then(handleJSON);

  }

  void addImage(String title, String artist, String date, String url) {
    var list = document.createElement('li');
    NodeValidatorBuilder _htmlValidator=new NodeValidatorBuilder.common()
      ..allowElement('img', attributes: ['src']);
    list.setInnerHtml('<img src="' + url + '" alt=""></img> <br> <p><b>' + title + '</b> ' + artist + ' <i>' + date + '</i></p>', validator:_htmlValidator);
    list.className = 'image_item';
    querySelector('#images').append(list);
  }

  // takes the json of all the art data and turns it into questions
  void handleJSON(String stringJSON) {
    Map raw = JSON.decode(stringJSON);
    data = raw['art'];
    data.forEach((item) {
      addImage(item['title'][0], item['artist'][0], item['date'][0], item['image']);
    });
  }
}
