# Kyu

Kyu is a stupidly simple, persistant, queue system.

## Requirements

- iOS 13.0+
- macOS 11.0+

## Installation

### Swift Package Manager

```
dependencies: [
    .package(url: "https://github.com/reddavis/Kyu", from: "2.0.0")
]
```
## Usage

Kyu has two parts to it; The `Kyu`, which manages job state and execution and the `Job` which does the actual work.

### The Job

A job must simply conform to the `Job` and `Codable` protocol.

A simple "Append new line to end of file" job could look something like:

```
final class AppendNewLineJob: Job
{
    // Internal
    let id: UUID
    var maximumNumberOfRetries: Int { 5 }
    var numberOfRetries = 0
    var executionDate = Date()
    
    let fileURL: URL
    let string: String
    
    // MARK: Initialization
    
    init(fileURL: URL, string: String)
    {
        self.id = UUID()
        self.fileURL = fileURL
        self.string = string
    }
    
    // MARK: Job
    
    func execute(onComplete: @escaping (Result<Void, Error>) -> Void)
    {
        do
        {
            let fileHandle = try FileHandle(forWritingTo: self.fileURL)
            try fileHandle.seekToEnd()
            fileHandle.write("\(self.string)\n".data(using: .utf8)!)
            fileHandle.closeFile()
            
            onComplete(.success(Void()))
        }
        catch
        {
            onComplete(.failure(error))
        }
    }
}
``` 

### The Kyu

The Kyu manages and executes jobs. It take a `URL` parameter, which is where it will persist the jobs.

```
let url = URL(string: ...)!
self.kyu = try Kyu<AppendNewLineJob>(url: url)

let job = AppendNewLineJob(fileURL: fileURL, string: "a string to append")
try kyu.add(job: job)
```

## License

Whatevs.
