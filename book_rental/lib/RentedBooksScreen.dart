import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'providers.dart';

class UserRentedBooksScreen extends StatefulWidget {
  final int userId;

  UserRentedBooksScreen({required this.userId});

  @override
  _UserRentedBooksScreenState createState() => _UserRentedBooksScreenState();
}

class _UserRentedBooksScreenState extends State<UserRentedBooksScreen> {
  late Future<List<dynamic>> _booksFuture;
  List<dynamic> books = []; // Updated books list

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final accessToken = authProvider.accessToken;
    _booksFuture = _fetchBooks(accessToken);
  }

  Future<List<dynamic>> _fetchBooks(String? accessToken) async {
    final url = 'http://127.0.0.1:8000/api/users/${widget.userId}/books/';
    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData;
    } else {
      throw Exception('Failed to load books');
    }
  }

  Future<void> _returnBook(int bookId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final accessToken = authProvider.accessToken;
    final url = 'http://127.0.0.1:8000/api/books/$bookId/return/';
    final response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Book returned successfully'),
        ),
      );
      setState(() {
        _booksFuture = _fetchBooks(accessToken);
        // Remove the book from the list
        books.removeWhere((book) => book['id'] == bookId);
      });
      // Show dialog after successful return
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Book Returned'),
            content: Text('You have successfully returned the book.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to return book'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Books rented by user'),
        backgroundColor: Colors.green, // Set the desired color for the app bar
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              books = snapshot.data!; // Update the books list
              return ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final bool? bookReturned = book['returned'];
                  if (bookReturned == null || !bookReturned) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ListTile(
                        title: Text(book['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Author: ${book['author']}'),
                            Text('Price: ${book['price']}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            await _returnBook(book['id']);
                            setState(() {
                              books.removeAt(
                                  index); // Remove the book from the list
                            });
                          },
                          child: Text('Return'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors
                                .green, // Set the desired color for the button
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return SizedBox(); // Return an empty SizedBox for returned books
                  }
                },
              );
            } else {
              return Center(
                child: Text('No books rented'),
              );
            }
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
