{
  description = "Default site configuration (placeholder)";

  outputs = { ... }: {
    homeModule = { ... }: {
      # This is a placeholder. Real site configs should set:
      # home.username = "your-username";
      # home.homeDirectory = "/home/your-username";  # or /Users/... on macOS
      home.username = "user";
      home.homeDirectory = "/home/user";
    };
  };
}