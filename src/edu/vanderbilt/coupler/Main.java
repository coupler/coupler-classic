package edu.vanderbilt.coupler;

import org.jruby.embed.ScriptingContainer;

public class Main {

  private Main() {
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
