package edu.vanderbilt.coupler;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import org.jruby.embed.ScriptingContainer;

public class Main {
  private static final Properties properties = new Properties();
  public static final String PROPFILE = "coupler.properties";
  static {
    InputStream stream = null;
    try {
      stream = Main.class.getResourceAsStream(PROPFILE);
      if (stream == null) {
        throw new RuntimeException("Resource not found: " + PROPFILE);
      }
      properties.load(stream);
    } catch (IOException ioe) {
      ioe.printStackTrace();
    } finally {
      if (stream != null) {
        try {
          stream.close();
        } catch (IOException e) {
          // silently ignore
        }
      }
    }
  }

  private Main() {
    System.out.printf("Coupler version: %s\nBuild date: %s\n\n",
        properties.getProperty("coupler.version"),
        properties.getProperty("build.timestamp"));

    ScriptingContainer container = new ScriptingContainer();
    String script =
      "require 'coupler/runner'\n" +
      "Coupler::Runner.new";
    container.runScriptlet(script);
  }

  public static void main(String[] args) {
    new Main();
  }
}
