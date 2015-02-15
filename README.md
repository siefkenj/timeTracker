# timeTracker
Web app to track time spent with people!

##API Design

```JSON
{ 
  <date>:{
    <personID>:{
      phoneNumber:'123-456-7890',
      times:[
        {
          start:<date>,
          end:<date>
        },
        ...
      ]      
    }      
  }
}
```
