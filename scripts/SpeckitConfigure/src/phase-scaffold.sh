#!/usr/bin/env bash
#
# Phase: Language-specific project scaffolding
# Source this from the main script, don't run directly
#

# ============================================================
# Language-specific project scaffolding
# ============================================================
phase_scaffold() {
    local project_dir="$1"
    local lang="$2"

    print_info "Creating basic scaffolding for $lang..."

    case "$lang" in
        rust)
            cat > "$project_dir/Cargo.toml" << EOF
[package]
name = "$PROJECT_NAME"
version = "0.1.0"
edition = "2021"

[dependencies]
anyhow = "1.0"
thiserror = "1.0"

[dev-dependencies]
tempfile = "3.0"
EOF
            mkdir -p "$project_dir/src"
            cat > "$project_dir/src/lib.rs" << 'EOF'
pub fn hello() -> &'static str {
    "Hello, world!"
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hello_returns_greeting() {
        assert_eq!(hello(), "Hello, world!");
    }
}
EOF
            cat > "$project_dir/src/main.rs" << 'EOF'
fn main() {
    println!("Hello, world!");
}
EOF
            ;;
        python)
            cat > "$project_dir/pyproject.toml" << EOF
[project]
name = "$PROJECT_NAME"
version = "0.1.0"
dependencies = []

[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = "test_*.py"
EOF
            mkdir -p "$project_dir/src" "$project_dir/tests"
            cat > "$project_dir/src/__init__.py" << 'EOF'
def hello() -> str:
    return "Hello, world!"
EOF
            cat > "$project_dir/tests/test_main.py" << 'EOF'
import pytest
from src import hello

def test_hello_returns_greeting():
    assert hello() == "Hello, world!"
EOF
            ;;
        go)
            cat > "$project_dir/go.mod" << EOF
module $PROJECT_NAME

go 1.21
EOF
            mkdir -p "$project_dir/src"
            cat > "$project_dir/src/main.go" << 'EOF'
package main

import "fmt"

func Hello() string {
    return "Hello, world!"
}

func main() {
    fmt.Println(Hello())
}
EOF
            cat > "$project_dir/src/main_test.go" << 'EOF'
package main

import "testing"

func TestHello(t *testing.T) {
    want := "Hello, world!"
    got := Hello()
    if got != want {
        t.Errorf("Hello() = %q, want %q", got, want)
    }
}
EOF
            ;;
        javascript|typescript)
            cat > "$project_dir/package.json" << EOF
{
  "name": "$PROJECT_NAME",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "test": "jest"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
EOF
            mkdir -p "$project_dir/src"
            cat > "$project_dir/src/index.js" << 'EOF'
export function hello() {
    return "Hello, world!";
}
EOF
            cat > "$project_dir/src/index.test.js" << 'EOF'
import { hello } from './index.js';

test('hello returns greeting', () => {
    expect(hello()).toBe('Hello, world!');
});
EOF
            ;;
        java)
            mkdir -p "$project_dir/src/main/java/com/example" "$project_dir/src/test/java/com/example"
            cat > "$project_dir/pom.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>$PROJECT_NAME</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>5.10.0</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
EOF
            cat > "$project_dir/src/main/java/com/example/App.java" << 'EOF'
package com.example;

public class App {
    public static String hello() {
        return "Hello, world!";
    }
}
EOF
            cat > "$project_dir/src/test/java/com/example/AppTest.java" << 'EOF'
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class AppTest {
    @Test
    void testHelloReturnsGreeting() {
        assertEquals("Hello, world!", App.hello());
    }
}
EOF
            ;;
        csharp)
            # Convert project name to PascalCase for namespace
            local csharp_name
            csharp_name="$(echo "$PROJECT_NAME" | sed 's/[-_]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}' | tr -d ' ')"
            cat > "$project_dir/${PROJECT_NAME}.csproj" << EOF
<Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
        <TargetFramework>net8.0</TargetFramework>
        <Nullable>enable</Nullable>
        <ImplicitUsings>enable</ImplicitUsings>
    </PropertyGroup>
</Project>
EOF
            cat > "$project_dir/Program.cs" << EOF
namespace ${csharp_name};

public static class Program
{
    public static string Hello() => "Hello, world!";

    public static void Main(string[] args)
    {
        Console.WriteLine(Hello());
    }
}
EOF
            cat > "$project_dir/ProgramTests.cs" << 'EOF'
using Xunit;

namespace ${csharp_name};

public class ProgramTests
{
    [Fact]
    public void HelloReturnsGreeting()
    {
        Assert.Equal("Hello, world!", Program.Hello());
    }
}
EOF
            ;;
        c)
            mkdir -p "$project_dir/src" "$project_dir/tests"
            cat > "$project_dir/CMakeLists.txt" << EOF
cmake_minimum_required(VERSION 3.10)
project($PROJECT_NAME C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

enable_testing()

add_executable(\${PROJECT_NAME} src/main.c)
add_test(NAME \${PROJECT_NAME}_test COMMAND \${PROJECT_NAME})
EOF
            cat > "$project_dir/src/main.c" << 'EOF'
#include <stdio.h>

const char* hello(void) {
    return "Hello, world!";
}

int main(void) {
    printf("%s\n", hello());
    return 0;
}
EOF
            cat > "$project_dir/tests/test_main.c" << 'EOF'
#include <stdio.h>
#include <string.h>
#include <assert.h>

const char* hello(void);

int main(void) {
    assert(strcmp(hello(), "Hello, world!") == 0);
    printf("All tests passed!\n");
    return 0;
}
EOF
            ;;
        cpp)
            mkdir -p "$project_dir/src" "$project_dir/tests"
            cat > "$project_dir/CMakeLists.txt" << EOF
cmake_minimum_required(VERSION 3.10)
project($PROJECT_NAME CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.14.0
)
set(gtest_force_shared_crt ON)
FetchContent_MakeAvailable(googletest)

add_executable(\${PROJECT_NAME} src/main.cpp)
target_link_libraries(\${PROJECT_NAME} gtest_main gtest)

include(GoogleTest)
gtest_discover_tests(\${PROJECT_NAME})
EOF
            cat > "$project_dir/src/main.cpp" << 'EOF'
#include <iostream>
#include <string>

std::string hello() {
    return "Hello, world!";
}

int main() {
    std::cout << hello() << std::endl;
    return 0;
}
EOF
            cat > "$project_dir/tests/test_main.cpp" << 'EOF'
#include <gtest/gtest.h>
#include "../src/main.cpp"

TEST(HelloTest, ReturnsGreeting) {
    EXPECT_EQ(hello(), "Hello, world!");
}
EOF
            ;;
        zig)
            cat > "$project_dir/build.zig" << EOF
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseMode();

    const exe = b.addExecutable(.{
        .name = "$PROJECT_NAME",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });

    b.installArtifact(exe);

    const test_step = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });

    const run_test = b.addRunArtifact(test_step);
    run_test.step.dependOn(&std.Build.defaultStep.step);

    if (b.args) |args| {
        run_test.addArgs(args);
    }

    const step = b.step("test", "Run the tests");
    step.dependOn(&run_test.step);
}
EOF
            mkdir -p "$project_dir/src"
            cat > "$project_dir/src/main.zig" << 'EOF'
const std = @import("std");

pub fn main() void {
    std.debug.print("{s}\n", .{hello()});
}

fn hello() []const u8 {
    return "Hello, world!";
}

test "hello returns greeting" {
    try std.testing.expectEqual(hello(), "Hello, world!");
}
EOF
            ;;
    esac

    print_success "Basic scaffolding created"
}