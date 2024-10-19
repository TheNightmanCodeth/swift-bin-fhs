{
  description = "Swift direnv template";
  outputs = {self}: {
    templates = {
      swift = {
        path = ./swift;
        name = "Swift";
        description = "Swift 6.0.1 development environment";
      };
    };
  };
}  
