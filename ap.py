from flask import Flask
app = Flask(__name__)

@app.route('/')
def homepage():
    return """
<!DOCTYPE html>
<head>
   <title>This is a test wesite</title>
   <link rel="stylesheet" href="http://stash.compjour.org/assets/css/foundation.css">
</head>
<body style="width: 880px; margin: auto;">  
    <H1>First register here</h1>
<body>

<form>

<label for="fname">FIRST NAME:
<Label><br>
<input type="text" id="fname"
<br><br>
<label for="lname">LAST NAME:
<Label><br>
<input type="text" id="lname"
<label><br>
<label for="email">Email ID:
<Label><br>
<input type="text" id="email"
<label><br>
<label for="phno">PHONE NUMBER:
<Label><br>
<input type="text" id="phno"
<label><br>
<label for="cars"> chose a car: </label>
<select id="cars" name="cars">
<option
value="saab">Saab</option>
<option
value="Volvo">Volvo</option>
<option
value="Fiat">Fiat</option>
<option
value="Audi">Audi</option>
<option
value="Mercetez">Mercitez</option>
<option
value="BMW">BMW</option>
<option
value="Jagur">Jagur</option>

</select>
<br><br>
<input type="submit"
value="submit">
</form>
 
    here's an <a href="https://images.app.goo.gl/kkbuAv5XYmeqNgAh8"> image</a>
    
     Here is <a href="https://www.youtube.com/watch?v=V9QcayMAfJs/"> demo</a>
  

   <img src="http://stash.compjour.org/assets/images/sunset.jpg" alt="it's a nice sunset">
    </a>
</body>
</html>
if __name__ == '__main__':
    app.run(debug=True, use_reloader=True)