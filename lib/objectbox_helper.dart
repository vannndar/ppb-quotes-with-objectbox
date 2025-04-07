import 'objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'quote.dart';

class ObjectBoxHelper {
  late final Store store;
  late final Box<Quote> quoteBox;

  ObjectBoxHelper._create(this.store) {
    quoteBox = Box<Quote>(store);
  }

  static Future<ObjectBoxHelper> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: dir.path);
    return ObjectBoxHelper._create(store);
  }

  List<Quote> getAllQuotes() => quoteBox.getAll();

  void addQuote(Quote quote) => quoteBox.put(quote);

  void updateQuote(Quote quote) => quoteBox.put(quote);

  void deleteQuote(Quote quote) => quoteBox.remove(quote.obxId);
}
