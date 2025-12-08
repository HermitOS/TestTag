using TestTag.ConsoleApp;

namespace TestTag.Tests;

public class CalculatorTests
{
    private Calculator _calculator;

    [SetUp]
    public void Setup()
    {
        _calculator = new Calculator();
    }

    [Test]
    public void Add_TwoPositiveNumbers_ReturnsCorrectSum()
    {
        // Arrange
        int a = 5;
        int b = 3;

        // Act
        int result = _calculator.Add(a, b);

        // Assert
        Assert.That(result, Is.EqualTo(8));
    }

    [Test]
    public void Add_NegativeAndPositiveNumber_ReturnsCorrectSum()
    {
        // Arrange
        int a = -5;
        int b = 3;

        // Act
        int result = _calculator.Add(a, b);

        // Assert
        Assert.That(result, Is.EqualTo(-2));
    }

    [Test]
    public void Add_TwoZeros_ReturnsZero()
    {
        // Arrange & Act
        int result = _calculator.Add(0, 0);

        // Assert
        Assert.That(result, Is.EqualTo(0));
    }

    /// <summary>
    /// Additional tests Divide method
    /// </summary>
    [Test]
    public void Divide_ByNonZeroNumber_ReturnsCorrectQuotient()
    {
        // Arrange
        int a = 10;
        int b = 2;

        // Act
        double result = _calculator.Divide(a, b);

        // Assert
        Assert.That(result, Is.EqualTo(5.0));
    }
}
